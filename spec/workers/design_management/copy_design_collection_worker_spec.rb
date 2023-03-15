# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::CopyDesignCollectionWorker, :clean_gitlab_redis_shared_state, feature_category: :design_management do
  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:target_issue) { create(:issue) }

    subject { described_class.new.perform(user.id, issue.id, target_issue.id) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, issue.id, target_issue.id] }

      specify { subject }
    end

    it 'calls DesignManagement::CopyDesignCollection::CopyService' do
      expect_next_instance_of(DesignManagement::CopyDesignCollection::CopyService) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      subject
    end

    it 'logs if there was an error calling the service' do
      message = 'Error message'

      allow_next_instance_of(DesignManagement::CopyDesignCollection::CopyService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.error(message: message))
      end

      expect(Gitlab::AppLogger).to receive(:warn).with(message)

      subject
    end
  end
end
