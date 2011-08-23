# Active Reload
## The only Rails boost tool that doesn't try to be too smart.

<a href='http://www.pledgie.com/campaigns/15547'><img alt='Donate Active Reload at www.pledgie.com' src='http://pledgie.com/campaigns/15547.png?skin_name=chrome' border='0' /></a>

Active Reload is a gem that changes a little when Rails code reloading is executed.
Normally Rails "forgets" your code after every request in development mode and loads again necessary
files during the request. If your application is big this can take lot of time especially on "dashboard" page
that uses lot of different classes.

However this constant reloading is not always necessary. This gem changes it so it occurs
before request and only when file was changed or added. It won't make reloading your app
faster but it will skip reloading when nothing changed and that saved second can really sum
up to a big value. It means that after change first request in development mode will reload the code
and take as much time as it takes without this gem but subsequent request will be faster until next
changes due to lack of code reloading.

## It works for you so you want to thank? There are many options:

 * Meet me at wroc_love.rb conference : http://wrocloverb.com/ and buy me a beer.
 * Tweet about the gem
 * Tell you friends to try it
 * Donate

## Y U NO BELIEVE ?

Watch these videos for comparison:

### 2 simultaneous movies:

http://youtubedoubler.com/1fts

### Spree in development mode without Active Reload
<a href='http://www.youtube.com/watch?v=KIOV5Me-83M'><img alt='Spree in development mode' src='http://img.youtube.com/vi/KIOV5Me-83M/0.jpg' border='0' /></a>

### Spree in development and Active Reload enabled

<a href='http://www.youtube.com/watch?v=HelS-mVnfI4'><img alt='Spree in development mode with enabled Active Reload' src='http://img.youtube.com/vi/HelS-mVnfI4/0.jpg' border='0' /></a>

## Installation

Simply add Active Reload to your Gemfile and bundle it up:

```ruby
  gem 'active_reload'
```

## Compatibility

Tested with Ruby `1.9.2` and `1.8.7`.
Tested with Rails `3.0.10` and `3.1.0.rc6` (older versions of this gem have been tested with older rails versions, check it by reading README.md in older tag versions)

## Notifications

You can subscribe to two notifications provided by this gem.

`active_reload.set_clear_dependencies_hook_replaced` event is triggered when the gem changes original rails hook for code reloading.

```ruby
ActiveSupport::Notifications.subscribe("active_reload.set_clear_dependencies_hook_replaced") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  msg = event.name
  # Ubuntu: https://github.com/splattael/libnotify, Example: Libnotify.show(:body => msg, :summary => Rails.application.class.name, :timeout => 2.5, :append => true)
  # Macos: http://segment7.net/projects/ruby/growl/
  puts Rails.logger.warn(" --- #{msg} --- ")
end
```

`active_support.dependencies.clear` event is triggered when code reloading is triggered by this gem.

```ruby
ActiveSupport::Notifications.subscribe("active_support.dependencies.clear") do |*args|
  msg = "Code reloaded!"
  # Ubuntu: https://github.com/splattael/libnotify, Example: Libnotify.show(:body => msg, :summary => Rails.application.class.name, :timeout => 2.5, :append => true)
  # Macos: http://segment7.net/projects/ruby/growl/
  puts Rails.logger.info(" --- #{msg} --- ")
end
```

## Links

 * http://blog.robert.pankowecki.pl/2011/06/faster-rails-development-part-2.html
 * http://blog.robert.pankowecki.pl/2011/05/get-faster-rails-development.html

## Testing & Contribution

```bash
cd active_reload

bundle install
cd test/dummy309/
bundle install
cd ../..

cd test/dummy310rc5/
bundle install
cd ../..

bundle exec rake test
```

## Do you want to reproduce the video experiment ? 

The tested spree version was: https://github.com/spree/spree/tree/42795d91d3680394ef70126e6660cac3da81e8a9

It was installed in sandbox mode:

```bash
  git clone git://github.com/spree/spree.git spree
  cd spree
  git checkout 42795d91d3680394ef70126e6660cac3da81e8a9
  bundle install
  rake sandbox
  cd sandbox
  # Edit Gemfile to add or remove active_reload support
  rails server
```

Here is the ruby script that walks through the site using capybara:

```ruby
require 'bbq/test' # https://github.com/drugpl/bbq
require 'benchmark'

shop = ["Ruby on Rails", "Apache", "Clothing", "Bags", "Mugs"]
admin = [
"Overview", 
"Orders", 
"Next", 
"Products", 
"Option Types", 
"Properties", 
"Prototypes", 
"Product Groups", 
"Reports", 
"Sales Total", 
"Configuration", 
"General Settings",
"Mail Methods",
"Tax Categories",
"Zones",
"States",
"Payment Methods",
"Taxonomies",
"Shipping Methods",
"Inventory Settings",
"Analytics Trackers",
"Complete List",
"Users",
"Promotions"
]

user = Bbq::TestUser.new(:driver => :selenium, :session => :default)
user.visit("/")

Benchmark.measure do

  shop.each do |link|
    user.click_on(link)
  end

  user.visit("/admin")
  user.fill_in("Email", :with => "spree@example.com")
  user.fill_in("Password", :with => "spree@example.com")
  user.click_button("Log In")

  admin.each do |link|
    user.click_on(link)
  end

  FileUtils.touch( Rails.root.join("app/controllers/application_controller.rb") )

  admin.first(5).each do |link|
    user.click_on(link)
  end

  user.click_on "Logout"

end
```
