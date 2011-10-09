require "active_reload/version"

module ActiveReload

  class Railtie < ::Rails::Railtie
    initializer :'active_reload.set_clear_dependencies_hook', :after => :set_clear_dependencies_hook do
      ActiveReload.replace!
    end
  end # Railtie

  module ProcInspector
    if RUBY_VERSION.start_with?("1.8")
      # Proc#source_location is not available in Ruby 1.8
      def source_file
        # Extract from format like this: "#<Proc:0xb750a994@/home/rupert/.rvm/gems/ruby-1.8.7-p174/gems/activerecord-3.0.9/lib/active_record/railtie.rb:74>"
        to_s.match(/.*@(.*):[0-9]+>/)[1]
      end
    else
      def source_file
        # ActionDispatch::Callbacks._call_callbacks.last.raw_filter.source_location
        # => ["/home/rupert/.rvm/gems/ruby-1.9.2-p180-fastrequire/gems/activerecord-3.0.9/lib/active_record/railtie.rb", 74]
        source_location.first
      end
    end

    def source?(file)
      source_file.match( Regexp.new(file) )
    end
  end

  def self.replace?
    !Rails.application.config.cache_classes && replace_proc?(proc_collection.last)
  end

  def self.proc_collection
    if rails31?
      proc_source._cleanup_callbacks
    else
      proc_source._call_callbacks
    end
  end

  def self.proc_source
    if rails31?
      ActionDispatch::Reloader
    else
      ActionDispatch::Callbacks
    end
  end
  
  def self.replace_proc?(last)
    last.respond_to?(:raw_filter) &&
    last.raw_filter.is_a?(Proc) &&
    last.raw_filter.extend(ProcInspector).source?("railties.*/lib/rails/application/bootstrap.rb")
  end

  def self.replace!
    return unless replace?
    
    ActiveSupport::Notifications.instrument("active_reload.set_clear_dependencies_hook_replaced") do

      changed_at = Proc.new do
        ActiveSupport::Dependencies.autoload_paths.map do |p|
          Dir["#{p}/**/*.rb"].map{|f| File.mtime(f) }
        end.flatten.max
      end

      last_change = Time.now

      replace_proc do
        change = changed_at.call
        if change > last_change
          last_change = change
          ActiveSupport::Notifications.instrument("active_support.dependencies.clear") do
            ActiveSupport::DescendantsTracker.clear
            ActiveSupport::Dependencies.clear
          end
        end
      end
    end
  end

  def self.replace_proc(&new)
    @replaced = proc_collection.pop
    if rails31?
      proc_source.to_prepare(&new)
      proc_source.__define_runner(:cleanup)
    else
      proc_source.before(&new)
    end
  end

  def self.rails3?
    Rails::VERSION::MAJOR == 3
  end

  def self.rails31?
    rails3? && Rails::VERSION::MINOR == 1
  end

  
end
