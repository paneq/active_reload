require 'test/unit'
require 'bbq/test'
require 'pathname'
require 'socket'
require 'timeout'

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

class ReloadTest < Bbq::TestCase
  include FileCommandHelper

  def test_rails309
    app_root = File.expand_path( File.join(File.dirname(__FILE__), '..', 'dummy309') )
    controller = File.join(app_root, 'app', 'controllers', 'root_controller.rb')

    create_file controller, <<-CONTROLLER
      class RootController < ApplicationController
        def index
          render :text => "first version"
        end
      end
    CONTROLLER

    begin
      pid = fork do
        Bundler.with_clean_env do
          Dir.chdir(app_root)
          #          exec("cd #{app_root} && pwd")
          #          exec("cd #{app_root} && bundle install --path vendor/bundle && bundle exec rails s --port 8899")
          puts "in fork"
          `bundle install --path vendor/bundle` # this does read the right Gemfile...!
          `bundle exec rails s --port 8899`
        end
      end

      sleep(5)
      wait_for_rails
      Capybara.app_host = "http://localhost:8899"
      user = Bbq::TestUser.new(:driver => :selenium)
      user.visit('/const/RootController') # RootController not loaded
      user.see!('nil')

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

      user.visit('/empty')                 # we should reload the code before the request because file changed
      user.visit('/const/RootController')
      user.see!('nil')                     # so the constant RootController should not be defined at that time

      user.visit('/root')         # load RootController
      user.see!('second version') # in second version

      user.visit('/const/RootController')
      user.see!('constant')                # so the constant RootController should not be defined at that time
    ensure
      server_pid_filepath = File.join(app_root, 'tmp', 'pids', 'server.pid')
      Process.kill("KILL", File.read(server_pid_filepath) ) if File.exist?(server_pid_filepath)
      Process.kill("KILL", pid)
    end
    
  end


  private


  def wait_for_rails
    Timeout::timeout(15) do
      while true do
        begin
          s = TCPSocket.new("127.0.0.1", 8899)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          #return false
        end
      end
    end
  end

end