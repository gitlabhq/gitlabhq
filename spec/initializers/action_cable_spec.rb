# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionCable', feature_category: :redis do
  describe 'redis config_command' do
    let!(:original_config) { ::ActionCable::Server::Base.config.cable }
    let!(:custom_config) do
      {
        adapter: 'redis',
        config_command: '/opt/generate-redis-password rails',
        url: 'redis://127.0.0.1:6379',
        id: 'foobar',
        channel_prefix: 'test_'
      }
    end

    let!(:expected_args) do
      {
        url: 'redis://127.0.0.1:6379',
        password: 'custom-redis-password',
        custom: {
          instrumentation_class: 'ActionCable'
        },
        id: 'foobar'
      }
    end

    before do
      allow(Gitlab::Popen).to receive(:popen).and_return(["password: 'custom-redis-password'\n", 0])

      ActionCable.server.restart
    end

    after do
      ::ActionCable::Server::Base.config.cable = original_config
      ActionCable.server.restart
    end

    it 'uses the specified password for Redis connection' do
      expect(::Redis).to receive(:new).with(expected_args)

      ::ActionCable::Server::Base.config.cable = custom_config
      ActionCable.server.pubsub.send(:redis_connection)
    end
  end
end
