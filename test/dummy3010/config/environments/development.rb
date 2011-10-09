require File.expand_path( File.join(File.dirname(__FILE__), '..', '..', '..', 'support', "defined_middleware") )

Dummy3010::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.middleware.insert_after(ActionDispatch::Static, DefinedMiddleware)
end

# http://railscasts.com/episodes/249-notifications-in-rails-3
ActiveSupport::Notifications.subscribe("active_support.dependencies.clear") do |*args|
  msg = "Code reloaded!"
  #  Libnotify.show(:body => msg, :summary => Rails.application.class.name, :timeout => 2.5, :append => true) # https://github.com/splattael/libnotify
  puts msg
  Rails.logger.info(" --- #{msg} --- ")
end

ActiveSupport::Notifications.subscribe("active_reload.set_clear_dependencies_hook_replaced") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  msg = event.name
  #  Libnotify.show(:body => msg, :summary => Rails.application.class.name, :timeout => 2.5, :append => true) # https://github.com/splattael/libnotify
  puts msg
  Rails.logger.warn(" --- #{msg} --- ")
end

# Log how dependencies (constants) are resolved automatically and when they are unloaded.
dependencies_logger_dir = File.join(Rails.root, 'log', 'dependencies')
FileUtils.mkpath(dependencies_logger_dir)
ActiveSupport::Dependencies.log_activity = true
ActiveSupport::Dependencies.logger = Logger.new(File.join(dependencies_logger_dir, Rails.env + '.log'))