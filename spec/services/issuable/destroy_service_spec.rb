# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DestroyService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    shared_examples_for 'service deleting todos' do
      it 'destroys associated todos asynchronously' do
        expect(TodosDestroyer::DestroyedIssuableWorker)
          .to receive(:perform_async)
          .with(issuable.id, issuable.class.name)

        subject.execute(issuable)
      end

      context 'when destroy_issuable_todos_async feature is disabled' do
        before do
          stub_feature_flags(destroy_issuable_todos_async: false)
        end

        it 'destroy associated todos synchronously' do
          expect_next_instance_of(TodosDestroyer::DestroyedIssuableWorker) do |worker|
            expect(worker)
              .to receive(:perform)
              .with(issuable.id, issuable.class.name)
          end

          subject.execute(issuable)
        end
      end
    end

    context 'when issuable is an issue' do
      let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

      it 'destroys the issue' do
        expect { service.execute(issue) }.to change { project.issues.count }.by(-1)
      end

      it 'updates open issues count cache' do
        expect_any_instance_of(Projects::OpenIssuesCountService).to receive(:refresh_cache)

        service.execute(issue)
      end

      it 'invalidates the issues count cache for the assignees' do
        expect_any_instance_of(User).to receive(:invalidate_cache_counts).once
        service.execute(issue)
      end

      it_behaves_like 'service deleting todos' do
        let(:issuable) { issue }
      end
    end

    context 'when issuable is a merge request' do
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: user, assignees: [user]) }

      it 'destroys the merge request' do
        expect { service.execute(merge_request) }.to change { project.merge_requests.count }.by(-1)
      end

      it 'updates open merge requests count cache' do
        expect_any_instance_of(Projects::OpenMergeRequestsCountService).to receive(:refresh_cache)

        service.execute(merge_request)
      end

      it 'invalidates the merge request caches for the MR assignee' do
        expect_any_instance_of(User).to receive(:invalidate_cache_counts).once
        service.execute(merge_request)
      end

      it_behaves_like 'service deleting todos' do
        let(:issuable) { merge_request }
      end
    end
  end
end
