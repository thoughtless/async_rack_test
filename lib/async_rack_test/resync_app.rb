# Turns an async rack app into a sync one. This let's you test the app with
# rack-test as if it were synchronous.
module AsyncRackTest
  class ResyncApp
    attr_reader :app
    def initialize(app)
      @app = app
    end

    def call(env)
      result = nil
      env['async.callback'] = method(:write_async_response)
      EM.run do
        response = app.call(env)
        if response[0] == -1
          EM.add_periodic_timer(0.1) do
            unless @async_response.nil?
              result = @async_response
              EM.stop
            end
          end
        else
          result = response
          EM.stop
        end
      end
      result
    end

    def write_async_response(response)
      @async_response = response
    end
  end
end
