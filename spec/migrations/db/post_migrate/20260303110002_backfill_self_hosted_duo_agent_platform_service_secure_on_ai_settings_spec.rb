# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillSelfHostedDuoAgentPlatformServiceSecureOnAiSettings, migration: :gitlab_main, feature_category: :duo_setting do
  let(:ai_settings) { table(:ai_settings) }
  let!(:ai_setting) { ai_settings.create!(self_hosted_duo_agent_platform_service_secure: initial_value) }

  describe '#up' do
    shared_examples 'backfills secure value from env' do
      before do
        stub_env('DUO_AGENT_PLATFORM_SERVICE_SECURE', env_value)
      end

      after do
        stub_env('DUO_AGENT_PLATFORM_SERVICE_SECURE', nil)
      end

      it 'sets self_hosted_duo_agent_platform_service_secure from env parsing' do
        migrate!

        expect(ai_setting.reload.self_hosted_duo_agent_platform_service_secure).to be(expected_value)
      end
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is truthy' do
      let(:initial_value) { false }
      let(:env_value) { 'yes' }
      let(:expected_value) { true }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is falsey' do
      let(:initial_value) { true }
      let(:env_value) { 'off' }
      let(:expected_value) { false }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is unrecognized' do
      let(:initial_value) { false }
      let(:env_value) { 'definitely-not-a-boolean' }
      let(:expected_value) { true }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is nil' do
      let(:initial_value) { false }
      let(:env_value) { nil }
      let(:expected_value) { true }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is case-variant truthy' do
      let(:initial_value) { false }
      let(:env_value) { 'TrUe' }
      let(:expected_value) { true }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is numeric falsey' do
      let(:initial_value) { true }
      let(:env_value) { '0' }
      let(:expected_value) { false }

      it_behaves_like 'backfills secure value from env'
    end

    context 'when DUO_AGENT_PLATFORM_SERVICE_SECURE is blank' do
      let(:initial_value) { false }
      let(:env_value) { '' }
      let(:expected_value) { true }

      it_behaves_like 'backfills secure value from env'
    end
  end
end
