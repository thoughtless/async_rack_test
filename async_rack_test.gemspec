# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "async_rack_test/version"

Gem::Specification.new do |s|
  s.name        = "async_rack_test"
  s.version     = AsyncRackTest::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paul Cortens"]
  s.email       = "paul@thoughtless.ca"
  s.homepage    = "http://github.com/thoughtless/async_rack_test"
  s.summary     = "async_rack_test-#{AsyncRackTest::Version::STRING}"
  s.description = "Extends rack-test to make working with EventMachine easier."
  s.license = 'MIT'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [ 'README.rdoc', 'CHANGELOG.rdoc']
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  # TODO: Add rack-test as a dependency
end
