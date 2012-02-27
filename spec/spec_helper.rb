require 'bundler/setup'
require 'async_rack_test'
require 'em-spec/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# # in spec/support/ and its subdirectories.
Dir[File.join(File.expand_path("..", __FILE__), "support/**/*.rb")].each {|f| require f}
