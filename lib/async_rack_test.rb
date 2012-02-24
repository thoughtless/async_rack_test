require 'rack/test'
require 'async_rack_test/resync_app'


# Adds aget, apost, etc. which treat an asynchronous rack-app as synchronous.
module AsyncRackTest
  module Methods
    include Rack::Test::Methods

    def sync_app
      self.class.instance_eval { alias_method :async_app, :app } unless self.respond_to?(:async_app)
      ResyncApp.new(async_app)
    end

    def use_sync
      self.instance_eval { alias :app :sync_app }
    end
    def use_async
      self.instance_eval { alias :app :async_app }
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
