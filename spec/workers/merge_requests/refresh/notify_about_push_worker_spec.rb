# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Refresh::NotifyAboutPushWorker, feature_category: :code_review_workflow do
  describe '#perform' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'master',
        target_branch: 'feature',
        target_project: project
      )
    end

    let(:worker) { described_class.new }
    let(:new_commits_data) do
      [
        { 'short_id' => 'abc123', 'title' => 'First commit' },
        { 'short_id' => 'def456', 'title' => 'Second commit' }
      ]
    end

    let(:existing_commits_data) do
      [
        { 'short_id' => 'old111', 'title' => 'Old first commit' },
        { 'short_id' => 'old999', 'title' => 'Old last commit' }
      ]
    end

    let(:total_new_commits_count) { 2 }
    let(:total_existing_commits_count) { 50 }

    subject(:perform) do
      worker.perform(
        merge_request.id,
        user.id,
        new_commits_data,
        total_new_commits_count,
        existing_commits_data,
        total_existing_commits_count
      )
    end

    before_all do
      project.add_developer(user)
    end

    context 'when all records exist' do
      it 'sends push notifications with pre-computed commit data' do
        expect_next_instance_of(NotificationService) do |service|
          expect(service).to receive(:push_to_merge_request_with_data).with(
            merge_request,
            user,
            new_commits_data: new_commits_data.map(&:symbolize_keys),
            total_new_commits_count: total_new_commits_count,
            existing_commits_data: existing_commits_data.map(&:symbolize_keys),
            total_existing_commits_count: total_existing_commits_count
          ).and_call_original
        end

        perform
      end
    end

    shared_examples 'does not send notifications' do
      it 'does not send notifications' do
        expect(NotificationService).not_to receive(:new)

        expect { perform }.not_to raise_error
      end
    end

    context 'when the merge request does not exist' do
      subject(:perform) do
        worker.perform(
          -1,
          user.id,
          new_commits_data,
          total_new_commits_count,
          existing_commits_data,
          total_existing_commits_count
        )
      end

      it_behaves_like 'does not send notifications'
    end

    context 'when the user does not exist' do
      subject(:perform) do
        worker.perform(
          merge_request.id,
          -1,
          new_commits_data,
          total_new_commits_count,
          existing_commits_data,
          total_existing_commits_count
        )
      end

      it_behaves_like 'does not send notifications'
    end

    context 'with empty commit data' do
      let(:new_commits_data) { [] }
      let(:existing_commits_data) { [] }
      let(:total_new_commits_count) { 0 }
      let(:total_existing_commits_count) { 0 }

      it 'still sends notifications' do
        expect_next_instance_of(NotificationService) do |service|
          expect(service).to receive(:push_to_merge_request_with_data)
        end

        perform
      end
    end

    describe 'idempotency' do
      it 'is not idempotent' do
        expect(described_class).not_to be_idempotent
      end
    end
  end
end
