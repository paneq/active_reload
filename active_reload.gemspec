# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_reload/version"

Gem::Specification.new do |s|
  s.name        = "active_reload"
  s.version     = ActiveReload::VERSION
  s.authors     = ["Robert Pankowecki"]
  s.email       = ["robert.pankowecki@gmail.com"]
  s.homepage    = "https://github.com/paneq/active_reload"
  s.summary     = %q{Reload Rails code in development mode only when change is deteced}
  s.description = %q{Reload Rails code in development mode only when change is deteced}

  s.rubyforge_project = "active_reload"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "active_support"
  s.add_development_dependency "bbq"
end
