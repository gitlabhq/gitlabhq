# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DestroyService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  subject(:service) { described_class.new(container: project, current_user: user) }

  describe '#execute' do
    context 'when issuable is a merge request' do
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: user, assignees: [user]) }

      it 'destroys the merge request' do
        expect { service.execute(merge_request) }.to change { project.merge_requests.count }.by(-1)
      end

      it 'updates open merge requests count cache' do
        expect_any_instance_of(Projects::OpenMergeRequestsCountService).to receive(:delete_cache)

        service.execute(merge_request)
      end

      it 'invalidates the merge request caches for the MR assignee' do
        expect_any_instance_of(User).to receive(:invalidate_cache_counts).once
        service.execute(merge_request)
      end

      it_behaves_like 'service deleting todos' do
        let(:issuable) { merge_request }
      end

      it_behaves_like 'service deleting label links' do
        let(:issuable) { merge_request }
      end

      context 'when the merge request has associated pipelines' do
        let!(:pipeline) { create(:ci_pipeline, project: project, merge_request: merge_request) }

        it 'destroys the associated pipelines' do
          expect { service.execute(merge_request) }.to change { project.all_pipelines.count }.by(-1)
        end
      end
    end
  end
end
