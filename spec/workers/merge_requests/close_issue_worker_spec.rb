# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CloseIssueWorker, feature_category: :code_review_workflow do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let!(:user) { create(:user) }
    let!(:project) { create(:project) }
    let!(:issue) { create(:issue, project: project) }
    let!(:merge_request) { create(:merge_request, source_project: project) }

    it 'calls the close issue service' do
      expect_next_instance_of(Issues::CloseService, container: project, current_user: user) do |service|
        expect(service).to receive(:execute).with(issue, commit: merge_request, skip_authorization: false)
      end

      subject.perform(project.id, user.id, issue.id, merge_request.id)
    end

    shared_examples 'when object does not exist' do
      it 'does not call the close issue service' do
        expect(Issues::CloseService).not_to receive(:new)

        expect { subject.perform(project.id, user.id, issue.id, merge_request.id) }
          .not_to raise_exception
      end
    end

    context 'when the project does not exist' do
      before do
        project.destroy!
      end

      it_behaves_like 'when object does not exist'
    end

    context 'when the user does not exist' do
      before do
        user.destroy!
      end

      it_behaves_like 'when object does not exist'
    end

    context 'when the issue does not exist' do
      before do
        issue.destroy!
      end

      it_behaves_like 'when object does not exist'
    end

    context 'when the merge request does not exist' do
      before do
        merge_request.destroy!
      end

      it_behaves_like 'when object does not exist'
    end
  end
end
