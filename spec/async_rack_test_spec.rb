require 'spec_helper'

describe AsyncRackTest do
  class DummyTest
    include AsyncRackTest::Methods
    def app
      @app ||= Proc.new do |env|
        EM.next_tick do
          env['async.callback'].call [200, {}, []]
        end
        [-1, {}, []]
      end
    end
  end

  describe AsyncRackTest::Methods do
    let(:test_obj) { DummyTest.new }
    describe '#sync_app' do
      it 'should be a ResyncApp' do
        expect(test_obj.sync_app).to be_kind_of(AsyncRackTest::ResyncApp)
      end
    end

    describe '#async_app' do
      it 'should be the original app' do
        expect(test_obj.async_app).to be_kind_of(Proc)
      end
    end

    describe '#app' do
      context 'default' do
        it 'should be the original app' do
          expect(test_obj.app).to eql(test_obj.async_app)
        end
      end
      context 'after calling #use_sync' do
        it 'should be a ResyncApp' do
          test_obj.use_sync
          expect(test_obj.app).to eql(test_obj.sync_app)
        end
        context 'then after calling #use_async' do
          it 'should be the original app' do
            test_obj.use_sync
            test_obj.use_async
            expect(test_obj.app).to eql(test_obj.async_app)
          end
        end
      end
    end

    describe '#aget' do
      it 'should set the app be a ResyncApp' do
        expect(test_obj).to receive(:use_sync)
        allow(test_obj).to receive(:get)
        allow(test_obj).to receive(:use_async)
        test_obj.aget '/'
      end
      it 'should call #call on #sync_app' do
        expect(test_obj.sync_app).to receive(:call).and_return([200, {}, []])
        test_obj.aget '/'
      end
      it 'should call #get' do
        expect(test_obj).to receive(:get)
        test_obj.aget '/'
      end
      it 'should put the app back to the original' do
        test_obj.aget '/'
        expect(test_obj.app).to eql(test_obj.async_app)
      end
    end
  end


  describe AsyncRackTest::ResyncApp do
    let(:resync_app) { AsyncRackTest::ResyncApp.new(DummyTest.new.app) }
    describe '#call' do
      it "should call #call on the passed in app" do
        expect(resync_app.app).to receive(:call).and_return([200, {}, []])
        resync_app.call({})
      end

      it "should return when the passed in app returns a status code other than -1", :slow => true do
        @trigger_async = nil
        async_app = Proc.new do |env|
          EM.add_periodic_timer(0.01) do
            if @trigger_async # This lets us control when the async behavior actually happens.
              env['async.callback'].call [200, {}, []]
            end
          end
          [-1, {}, []]
        end
        resync_app = AsyncRackTest::ResyncApp.new(async_app)

        @result = nil
        thread = Thread.new { @result = resync_app.call({}) }

        sleep 1 # Give some time to guarantee the thread has had time to run.
        expect(@result).to be_nil
        @trigger_async = true
        thread.join
        expect(@result).to eql([200, {}, []])
      end

      it "should return when the passed in app throws :async", :slow => true do
        @trigger_async = nil
        async_app = Proc.new do |env|
          EM.add_periodic_timer(0.01) do
            if @trigger_async # This lets us control when the async behavior actually happens.
              env['async.callback'].call [200, {}, []]
            end
          end
          throw :async
        end
        resync_app = AsyncRackTest::ResyncApp.new(async_app)

        @result = nil
        thread = Thread.new { @result = resync_app.call({}) }

        sleep 1 # Give some time to guarantee the thread has had time to run.
        expect(@result).to be_nil
        @trigger_async = true
        thread.join
        expect(@result).to eql([200, {}, []])
      end

      it "should return instantly when the passed in app is not async", :slow => true do
        @trigger_async = nil
        async_app = Proc.new do |env|
          EM.add_periodic_timer(0.01) do
            if @trigger_async # This lets us control when the async behavior actually happens.
              raise 'This should never happen'
            end
          end
          [200, {}, []]
        end
        resync_app = AsyncRackTest::ResyncApp.new(async_app)

        @result = nil
        thread = Thread.new { @result = resync_app.call({}) }

        sleep 1 # Give some time to guarantee the thread has had time to run.
        expect(@result).to eql([200, {}, []])
        @trigger_async = true
        sleep 1 # Give some time to guarantee the thread has had time to run.
        thread.join
      end

      context "#sync_app doesn't respond within the set timeout", :slow => true do
        let(:slow_app) do
          Proc.new do |env|
            EM.add_timer(1.1) do
              env['async.callback'].call [200, {}, []]
            end
            [-1, {}, []]
          end
        end
        let(:resync_app) { AsyncRackTest::ResyncApp.new(slow_app, :timeout => 1) }

        it "should time out" do
          expect {
            resync_app.call({})
          }.to raise_error(AsyncRackTest::Timeout)
        end
      end
    end
  end
end
