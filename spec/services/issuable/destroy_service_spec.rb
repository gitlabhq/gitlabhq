require 'spec_helper'

describe Issuable::DestroyService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when issuable is an issue' do
      let!(:issue) { create(:issue, project: project, author: user) }

      it 'destroys the issue' do
        expect { service.execute(issue) }.to change { project.issues.count }.by(-1)
      end

      it 'updates open issues count cache' do
        expect_any_instance_of(Projects::OpenIssuesCountService).to receive(:refresh_cache)

        service.execute(issue)
      end
    end

    context 'when issuable is a merge request' do
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: user) }

      it 'destroys the merge request' do
        expect { service.execute(merge_request) }.to change { project.merge_requests.count }.by(-1)
      end

      it 'updates open merge requests count cache' do
        expect_any_instance_of(Projects::OpenMergeRequestsCountService).to receive(:refresh_cache)

        service.execute(merge_request)
      end
    end
  end
end
