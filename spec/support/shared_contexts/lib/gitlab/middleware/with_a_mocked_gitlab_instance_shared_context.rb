# frozen_string_literal: true

RSpec.shared_context 'with a mocked GitLab instance' do
  let(:rack_stack) do
    rack = Rack::Builder.new do
      use ActionDispatch::Session::CacheStore
      use ActionDispatch::Flash
    end

    rack.run(subject)
    rack.to_app
  end

  let(:observe_env) do
    Module.new do
      attr_reader :env

      def call(env)
        @env = env
        super
      end
    end
  end

  let(:request) { Rack::MockRequest.new(rack_stack) }

  subject do
    Gitlab::Middleware::ReadOnly.new(fake_app).tap do |app|
      app.extend(observe_env)
    end
  end
end
