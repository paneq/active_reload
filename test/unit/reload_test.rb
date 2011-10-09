require 'test/unit'
require 'rubygems'
require 'bbq/test'
require 'pathname'
require 'socket'
require 'timeout'
require 'fileutils'

module FileCommandHelper
  def create_file(path, content)
    file = Pathname.new(path) # ActiveReload.root.join(path)
    FileUtils.mkdir_p(file.dirname)
    file.open('w') { |f| f.write(content) }
  end

  attr_accessor :output

  def run_cmd(command)
    self.output = Bundler.with_clean_env { `#{command} 2>&1` }
    raise "`#{command}` failed with:\n#{output}" unless $?.success?
  end
end

#module Sleepy
#  def visit(path)
#    super.tap{
#      puts path
#      sleep(5)
#    }
#  end
#end

class ReloadTest < Bbq::TestCase
  include FileCommandHelper

  %w(3010 310rc6).each_with_index do |version, index|
    define_method(:"test_rails#{version}") do
      app_port      = 8898 + index
      app_root      = File.expand_path( File.join(File.dirname(__FILE__), '..', "dummy#{version}") )
      app_gemfile   = File.join(app_root, 'Gemfile')
      app_vendor    = File.join(app_root, 'vendor/bundle')
      app_pid_file  = File.join(app_root, 'tmp', 'pids', 'server.pid')
      controller    = File.join(app_root, 'app', 'controllers', 'root_controller.rb')

      create_file controller, <<-CONTROLLER
        class RootController < ApplicationController
          def index
            render :text => "first version"
          end
        end
      CONTROLLER

      begin
        pid = fork do
          Dir.chdir(app_root)
          ENV['BUNDLE_GEMFILE'] = app_gemfile
          #puts ENV['BUNDLE_GEMFILE']
          #puts `bundle install --path #{app_vendor}` # Why it does not work ?
          #puts `bundle install --system` # This does not sometimes work well too...
          `bundle exec rails s --port #{app_port}`
        end
      
        wait_for_rails(app_port)
        Capybara.app_host = "http://localhost:#{app_port}"
        user = Bbq::TestUser.new(:driver => :selenium)
        #user.extend(Sleepy)
        # VITODO: user.visit('/rails/version') && user.see!(...)
        user.visit('/const/RootController') # RootController not loaded
        user.see!('nil')

        user.visit('/root')        # load RootController
        user.see!('first version') # in first version

        user.visit('/const/RootController')
        user.see!('constant')

        user.visit('/root')        # load RootController
        user.see!('first version') # in first version

        user.visit('/const/RootController')
        user.see!('constant')

        user.visit('/empty')                 # rails would reload the code after /root request but we don't
        user.visit('/const/RootController')
        user.see!('constant')                # so the constant RootController should be still defined

        create_file controller, <<-CONTROLLER
          class RootController < ApplicationController
            def index
              render :text => "second version"
            end
          end
        CONTROLLER

        # TODO?: reload even earlier in middleware ?
        # user.visit('/const/RootController')
        # user.see!('nil')

        user.visit('/empty')                 # we should reload the code before this request because file changed
        user.visit('/const/RootController')
        user.see!('nil')                     # so the constant RootController should not be defined at that time

        user.visit('/root')         # load RootController
        user.see!('second version') # in second version

        user.visit('/const/RootController')
        user.see!('constant')
      ensure
        Process.kill("KILL", File.read(app_pid_file).to_i.tap{|x| puts x} ) if File.exist?(app_pid_file)
        Process.kill("KILL", pid.to_i.tap{|x| puts x})
        begin
          3.times{ wait_for_rails(app_port, 0.5); sleep(1) }
          fail("Could not stop the server...")
        rescue Timeout::Error
        end
      end

    end
  end


  private


  def wait_for_rails(port, seconds = 15)
    Timeout::timeout(seconds) do
      while true do
        begin
          s = TCPSocket.new("127.0.0.1", port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET
          #return false
        end
      end
    end
  end

end