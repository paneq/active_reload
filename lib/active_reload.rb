require "active_reload/version"

module ActiveReload

  class Railtie < ::Rails::Railtie
    initializer :'active_reload.set_clear_dependencies_hook', :after => :set_clear_dependencies_hook do
      ActiveReload.replace!
    end
  end # Railtie

  def self.replace?
    !Rails.application.config.cache_classes && replace_proc?(ActionDispatch::Callbacks.instance_variable_get(:@_call_callbacks).last)
  end
  
  def self.replace_proc?(last)
    last.respond_to?(:raw_filter) &&
      last.raw_filter.is_a?(Proc) &&
      last.raw_filter.source_location.first.match( Regexp.new("railties.*/lib/rails/application/bootstrap.rb") )
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
    replaced = ActionDispatch::Callbacks.instance_variable_get(:@_call_callbacks).pop
    ActionDispatch::Callbacks.before(&new)
  end

  
end
