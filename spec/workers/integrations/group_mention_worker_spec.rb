# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GroupMentionWorker, :clean_gitlab_redis_shared_state, feature_category: :integrations do
  describe '#perform' do
    let(:worker) { described_class.new }
    let(:service_class) { Integrations::GroupMentionService }

    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:issue) { create(:issue, confidential: false, project: project, author: user) }
    let(:hook_data) { issue.to_hook_data(user) }
    let(:is_confidential) { issue.confidential? }

    let(:args) do
      {
        mentionable_type: 'Issue',
        mentionable_id: issue.id,
        hook_data: hook_data,
        is_confidential: is_confidential
      }
    end

    it 'executes the service' do
      expect_next_instance_of(service_class, issue, hook_data: hook_data, is_confidential: is_confidential) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(args)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [args] }
    end

    context 'when mentionable_type is not supported' do
      let(:args) do
        super().merge(
          mentionable_type: 'Unsupported',
          mentionable_id: 23
        )
      end

      it 'does not execute the service' do
        expect(service_class).not_to receive(:new)

        worker.perform(args)
      end

      it 'logs an error' do
        expect(Sidekiq.logger).to receive(:error).with({
          message: 'Integrations::GroupMentionWorker: mentionable not supported',
          mentionable_type: 'Unsupported',
          mentionable_id: 23
        })

        worker.perform(args)
      end
    end

    context 'when mentionable cannot be found' do
      let(:args) { super().merge(mentionable_id: non_existing_record_id) }

      it 'does not execute the service' do
        expect(service_class).not_to receive(:new)

        worker.perform(args)
      end
    end
  end
end
