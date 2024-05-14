# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SidekiqShardAwarenessValidation, feature_category: :scalability do
  let(:app) { ->(_env) { Sidekiq.redis(&:ping) } }
  let(:env) { { 'PATH_INFO' => path } }

  around do |example|
    original_state = Thread.current[:validate_sidekiq_shard_awareness]
    Thread.current[:validate_sidekiq_shard_awareness] = nil

    example.run

    Thread.current[:validate_sidekiq_shard_awareness] = original_state
  end

  describe '#call' do
    let(:path) { 'api/v4/projects/1' }

    subject(:app_call) { described_class.new(app).call(env) }

    it 'enables shard-awareness check within the context of a request' do
      expect { Sidekiq.redis(&:ping) }.not_to raise_error
      expect { app_call }.to raise_error(Gitlab::SidekiqSharding::Validator::UnroutedSidekiqApiError)
    end

    shared_examples 'no errors for sidekiq UI' do
      it 'does not enable validation' do
        expect { Sidekiq.redis(&:ping) }.not_to raise_error
        expect { app_call }.not_to raise_error
      end
    end

    context 'when using sidekiq UI path' do
      let(:path) { '/admin/sidekiq/queues' }

      it_behaves_like 'no errors for sidekiq UI'

      context 'with relative path' do
        let(:relative_url_root) { '/gitlab' }

        before do
          stub_config_setting(relative_url_root: relative_url_root)
        end

        it_behaves_like 'no errors for sidekiq UI'
      end
    end
  end
end
