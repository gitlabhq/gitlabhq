require 'spec_helper'

describe Issuable::DestroyService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when issuable is an issue' do
      let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

      it 'destroys the issue' do
        expect { service.execute(issue) }.to change { project.issues.count }.by(-1)
      end

      it 'updates open issues count cache' do
        expect_any_instance_of(Projects::OpenIssuesCountService).to receive(:refresh_cache)

        service.execute(issue)
      end

      it 'updates the todo caches for users with todos on the issue' do
        create(:todo, target: issue, user: user, author: user, project: project)

        expect { service.execute(issue) }
          .to change { user.todos_pending_count }.from(1).to(0)
      end

      it 'invalidates the issues count cache for the assignees' do
        expect_any_instance_of(User).to receive(:invalidate_cache_counts).once
        service.execute(issue)
      end
    end

    context 'when issuable is a merge request' do
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: user, assignee: user) }

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

      it 'updates the todo caches for users with todos on the merge request' do
        create(:todo, target: merge_request, user: user, author: user, project: project)

        expect { service.execute(merge_request) }
          .to change { user.todos_pending_count }.from(1).to(0)
      end
    end
  end
end
