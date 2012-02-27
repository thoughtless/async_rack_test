require 'rack/test'
require 'async_rack_test/resync_app'


# Adds aget, apost, etc. which treat an asynchronous rack-app as synchronous.
module AsyncRackTest
  class Timeout < StandardError; end

  module Methods
    include Rack::Test::Methods

    # The original app
    def async_app
      @async_app ||= app
    end
    def sync_app
      @sync_app ||= begin
        ResyncApp.new(async_app)
      end
    end

    def use_sync
      async_app # Ensure we have cached the original app first.
      self.instance_eval { class << self; self; end }.class_eval { alias :app :sync_app }
    end
    def use_async
      async_app # Ensure we have cached the original app first.
      self.instance_eval { class << self; self; end }.class_eval { alias :app :async_app }
    end

    %w(get put post delete head options).each do |m|
      eval <<-RUBY, binding, __FILE__, __LINE__ + 1
      def a#{m}(*args)
        use_sync
        #{m}(*args)
        use_async
      end
      RUBY
    end

  end
end
