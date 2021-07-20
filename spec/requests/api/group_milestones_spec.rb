# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupMilestones do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be(:closed_milestone) { create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone') }
  let_it_be(:milestone) { create(:milestone, group: group, title: 'version2', description: 'open milestone') }

  let(:route) { "/groups/#{group.id}/milestones" }

  it_behaves_like 'group and project milestones', "/groups/:id/milestones"

  describe 'GET /groups/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let_it_be(:ancestor_group) { create(:group, :private) }
      let_it_be(:ancestor_group_milestone) { create(:milestone, group: ancestor_group) }
      let_it_be(:params) { { include_parent_milestones: true } }

      before_all do
        group.update!(parent: ancestor_group)
      end

      shared_examples 'listing all milestones' do
        it 'returns correct list of milestones' do
          get api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(milestones.size)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when user has access to ancestor groups' do
        let(:milestones) { [ancestor_group_milestone, milestone, closed_milestone] }

        before do
          ancestor_group.add_guest(user)
          group.add_guest(user)
        end

        it_behaves_like 'listing all milestones'

        context 'when iids param is present' do
          let_it_be(:params) { { include_parent_milestones: true, iids: [milestone.iid] } }

          it_behaves_like 'listing all milestones'
        end
      end

      context 'when user has no access to ancestor groups' do
        let(:user) { create(:user) }

        before do
          group.add_guest(user)
        end

        it_behaves_like 'listing all milestones' do
          let(:milestones) { [milestone, closed_milestone] }
        end
      end
    end
  end

  describe 'GET /groups/:id/milestones/:milestone_id/issues' do
    let!(:issue) { create(:issue, project: project, milestone: milestone) }

    def perform_request
      get api("/groups/#{group.id}/milestones/#{milestone.id}/issues", user)
    end

    it 'returns multiple issues without performing N + 1' do
      perform_request

      control_count = ActiveRecord::QueryRecorder.new { perform_request }.count

      create(:issue, project: project, milestone: milestone)

      expect { perform_request }.not_to exceed_query_limit(control_count)
    end
  end

  def setup_for_group
    context_group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    context_group.add_developer(user)
    public_project.update!(namespace: context_group)
    context_group.reload
  end
end
