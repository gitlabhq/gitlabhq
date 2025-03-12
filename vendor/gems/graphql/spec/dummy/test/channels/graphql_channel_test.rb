# frozen_string_literal: true
require "test_helper"

class GraphqlChannelTest < ActionCable::Channel::TestCase
  module RealChannelStub
    def confirmed?
      subscription_confirmation_sent?
    end

    def real_streams
      streams
    end
  end

  def assert_has_real_stream(stream_name)
    assert subscription.real_streams.key?(stream_name), "Expected Stream #{stream_name.inspect} to be present in #{subscription.real_streams.keys}"
  end

  def setup
    @prev_server = ActionCable.server
    @server = TestServer.new(subscription_adapter: ActionCable::SubscriptionAdapter::Async)
    @server.config.allowed_request_origins = [ 'http://rubyonrails.com' ]

    ActionCable.instance_variable_set(:@server, @server)
  end

  def teardown
    ActionCable.instance_variable_set(:@server, @prev_server)
  end

  def wait_for_async
    wait_for_executor Concurrent.global_io_executor
  end

  def run_in_eventmachine
    yield
    wait_for_async
  end

  def wait_for_executor(executor)
    # do not wait forever, wait 2s
    timeout = 2
    until executor.completed_task_count == executor.scheduled_task_count
      sleep 0.1
      timeout -= 0.1
      raise "Executor could not complete all tasks in 2 seconds" unless timeout > 0
    end
  end

  class Connection < ActionCable::Connection::Base
    attr_reader :websocket

    def send_async(method, *args)
      send method, *args
    end

    public :handle_close
  end


  module InterceptTransmit
    def transmit(msg)
      intercepted_messages << JSON.parse(msg)
      super
    end

    def intercepted_messages
      @intercepted_messages ||= []
    end
  end

  test "it subscribes and unsubscribes" do
    run_in_eventmachine do
      env = Rack::MockRequest.env_for "/test", "HTTP_HOST" => "localhost", "HTTP_CONNECTION" => "upgrade", "HTTP_UPGRADE" => "websocket", "HTTP_ORIGIN" => "http://rubyonrails.com"

      @connection = Connection.new(ActionCable.server, env).tap do |connection|
        connection.process
        assert_predicate connection.websocket, :possible?

        wait_for_async
        assert_predicate connection.websocket, :alive?
        connection.websocket.singleton_class.prepend(InterceptTransmit)
      end

      @connection.subscriptions.add({"identifier" => "{\"channel\": \"GraphqlChannel\"}"})

      @subscription = @connection.subscriptions.instance_variable_get(:@subscriptions).values.first
      @subscription.singleton_class.prepend(RealChannelStub)
      assert subscription.confirmed?

      subscription.execute({
        "query" => "subscription { payload(id: \"abc\") { value } }"
      })
      wait_for_async

      sub_id = subscription.instance_variable_get(:@subscription_ids).first
      subscription_stream = "graphql-subscription:#{sub_id}"
      assert_has_real_stream subscription_stream
      topic_stream = "graphql-event::payload:id:abc"
      assert_has_real_stream topic_stream

      subscription.make_trigger({ "field" => "payload", "arguments" => { "id" => "abc"}, "value" =>  19 })

      wait_for_async

      @connection.handle_close
      wait_for_async

      expected_data = [
        {"identifier"=>"{\"channel\": \"GraphqlChannel\"}", "type"=>"confirm_subscription"},
        {"identifier"=>"{\"channel\": \"GraphqlChannel\"}", "message"=>{"result"=>{"data"=>{}}, "more"=>true}},
        {"identifier"=>"{\"channel\": \"GraphqlChannel\"}", "message"=>{"result"=>{"data"=>{"payload"=>{"value"=>19}}}, "more"=>true}},
        {"identifier"=>"{\"channel\": \"GraphqlChannel\"}", "message"=>{"more"=>false}},
      ]
      assert_equal expected_data, @connection.websocket.intercepted_messages
    end
  end

  class TestServer
    include ActionCable::Server::Connections
    include ActionCable::Server::Broadcasting

    attr_reader :logger, :config, :mutex

    class FakeConfiguration < ActionCable::Server::Configuration
      attr_accessor :subscription_adapter, :log_tags, :filter_parameters

      def initialize(subscription_adapter:)
        @log_tags = []
        @filter_parameters = []
        @subscription_adapter = subscription_adapter
      end

      def pubsub_adapter
        @subscription_adapter
      end
    end

    def initialize(subscription_adapter: SuccessAdapter)
      @logger = ActiveSupport::TaggedLogging.new ActiveSupport::Logger.new(StringIO.new)
      @config = FakeConfiguration.new(subscription_adapter: subscription_adapter)
      @mutex = Monitor.new
    end

    def pubsub
      @pubsub ||= @config.subscription_adapter.new(self)
    end

    def event_loop
      @event_loop ||= ActionCable::Connection::StreamEventLoop.new.tap do |loop|
        loop.instance_variable_set(:@executor, Concurrent.global_io_executor)
      end
    end

    def worker_pool
      @worker_pool ||= ActionCable::Server::Worker.new(max_size: 5)
    end
  end
end
