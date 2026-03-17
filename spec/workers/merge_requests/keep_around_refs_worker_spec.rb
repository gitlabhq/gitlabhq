# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::KeepAroundRefsWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:merge_request_diff) { merge_request.merge_request_diff }

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:project_ids) { [project.id] }
    let(:shas) { [merge_request_diff.start_commit_sha, merge_request_diff.head_commit_sha] }
    let(:source) { 'MergeRequestDiff' }

    context 'with missing required parameters' do
      it 'does nothing when project_ids is empty' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform([], shas, source)
      end

      it 'does nothing when shas is empty' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(project_ids, [], source)
      end

      it 'does nothing when project_ids is nil' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(nil, shas, source)
      end

      it 'does nothing when shas is nil' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(project_ids, nil, source)
      end
    end

    context 'with valid arguments' do
      it 'calls the keep around refs service' do
        expect_next_instance_of(
          MergeRequests::KeepAroundRefsService,
          project_ids: project_ids,
          shas: shas,
          source: source
        ) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(project_ids, shas, source)
      end

      it 'handles a single project_id' do
        expect_next_instance_of(
          MergeRequests::KeepAroundRefsService,
          project_ids: [project.id],
          shas: [merge_request_diff.head_commit_sha],
          source: 'MergeRequest'
        ) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform([project.id], [merge_request_diff.head_commit_sha], 'MergeRequest')
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project_ids, shas, source] }
    end
  end
end
