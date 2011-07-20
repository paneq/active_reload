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
    app_root      = File.expand_path( File.join(File.dirname(__FILE__), '..', 'dummy309') )
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
        puts `bundle install --path #{app_vendor}`
        `bundle exec rails s --port 8899`
      end
      
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
      Process.kill("KILL", File.read(app_pid_file).to_i.tap{|x| puts x} ) if File.exist?(app_pid_file)
      Process.kill("KILL", pid.to_i.tap{|x| puts x})
    end

  end


  private


  def wait_for_rails(seconds = 15)
    Timeout::timeout(seconds) do
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