# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CleanupRefWorker, :sidekiq_inline, feature_category: :code_review_workflow do
  include ExclusiveLeaseHelpers

  let_it_be(:source_project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: source_project) }

  let(:worker) { described_class.new }
  let(:only) { :all }

  subject { worker.perform(merge_request.id, only) }

  it 'does remove all merge request refs' do
    expect(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
    expect(merge_request.target_project.repository)
      .to receive(:delete_refs)
      .with(merge_request.ref_path, merge_request.merge_ref_path, merge_request.train_ref_path)

    subject
  end

  context 'when only is :train' do
    let(:only) { :train }

    it 'does remove only car merge request train ref' do
      expect(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
      expect(merge_request.target_project.repository)
        .to receive(:delete_refs)
        .with(merge_request.train_ref_path)

      subject
    end
  end

  context 'when max retry attempts reach' do
    let(:lease_key) { "projects/#{merge_request.target_project_id}/serialized_remove_refs" }
    let!(:lease) { stub_exclusive_lease_taken(lease_key) }

    it 'does not raise error' do
      expect(lease).to receive(:try_obtain).exactly(described_class::LOCK_RETRY + 1).times
      expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
