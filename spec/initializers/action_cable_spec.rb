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

  describe 'config' do
    before do
      stub_env('ACTION_CABLE_DISABLE_REQUEST_FORGERY_PROTECTION', disable_request_forgery_protection.to_s)
      stub_rails_env(rails_env) if rails_env
      stub_config_setting(relative_url_root: '/gitlab/root', url: 'example.com', https: true)

      load Rails.root.join('config/initializers/action_cable.rb')
    end

    around do |example|
      old = config.deep_dup
      Rails.application.config.action_cable.clear
      example.run
    ensure
      Rails.application.config.action_cable = old
    end

    let(:rails_env) { nil }
    let(:disable_request_forgery_protection) { false }

    subject(:config) { Rails.application.config.action_cable }

    describe 'mount_path' do
      subject { config.mount_path }

      it { is_expected.to eq('/-/cable') }
    end

    describe 'url' do
      subject { config.url }

      it { is_expected.to eq('/gitlab/root/-/cable') }
    end

    describe 'worker_pool_size' do
      subject { config.worker_pool_size }

      it { is_expected.to eq(Gitlab::ActionCable::Config.worker_pool_size) }
    end

    describe 'allow_request_origins' do
      subject { config.allowed_request_origins }

      context 'when in test' do
        let(:rails_env) { 'test' }

        it { is_expected.to eq(['example.com']) }
      end

      context 'when in development' do
        let(:rails_env) { 'development' }

        it { is_expected.to eq(['example.com']) }
      end

      context 'when in production' do
        let(:rails_env) { 'production' }

        it { is_expected.to eq(nil) }
      end
    end

    describe 'disable_request_forgery_protection' do
      subject { config.disable_request_forgery_protection }

      context 'when in test' do
        let(:rails_env) { 'test' }

        it { is_expected.to eq(false) }
      end

      context 'when in development' do
        let(:rails_env) { 'development' }
        let(:disable_request_forgery_protection) { true }

        it { is_expected.to eq(true) }
      end

      context 'when in production' do
        let(:rails_env) { 'production' }

        it { is_expected.to eq(nil) }
      end
    end
  end
end
