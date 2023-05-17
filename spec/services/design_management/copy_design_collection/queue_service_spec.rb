# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::CopyDesignCollection::QueueService, :clean_gitlab_redis_shared_state,
  feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:target_issue, refind: true) { create(:issue) }
  let_it_be(:design) { create(:design, issue: issue, project: issue.project) }

  subject { described_class.new(user, issue, target_issue).execute }

  before do
    enable_design_management
  end

  it 'returns an error if user does not have permission' do
    expect(subject).to be_kind_of(ServiceResponse)
    expect(subject).to be_error
    expect(subject.message).to eq('User cannot copy designs to issue')
  end

  context 'when user has permission' do
    before_all do
      issue.project.add_reporter(user)
      target_issue.project.add_reporter(user)
    end

    it 'returns an error if design collection copy_state is not queuable' do
      target_issue.design_collection.start_copy!

      expect(subject).to be_kind_of(ServiceResponse)
      expect(subject).to be_error
      expect(subject.message).to eq('Target design collection copy state must be `ready`')
    end

    it 'sets the design collection copy state' do
      expect { subject }.to change { target_issue.design_collection.copy_state }.from('ready').to('in_progress')
    end

    it 'queues a DesignManagement::CopyDesignCollectionWorker', :clean_gitlab_redis_queues do
      expect { subject }.to change(DesignManagement::CopyDesignCollectionWorker.jobs, :size).by(1)
    end

    it 'returns success' do
      expect(subject).to be_kind_of(ServiceResponse)
      expect(subject).to be_success
    end
  end
end
