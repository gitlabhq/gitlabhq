# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupMilestones, feature_category: :team_planning do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: organization) }
  let_it_be_with_refind(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group, organization: organization) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be(:closed_milestone) do
    create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone')
  end

  let_it_be_with_reload(:milestone) do
    create(:milestone, group: group, title: 'version2', description: 'open milestone', updated_at: 4.days.ago)
  end

  let(:route) { "/groups/#{group.id}/milestones" }

  shared_examples 'listing all milestones' do
    it 'returns correct list of milestones' do
      get api(route, user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(milestones.size)
      expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
    end
  end

  it_behaves_like 'group and project milestones', "/groups/:id/milestones"

  describe 'GET /groups/:id/milestones' do
    context 'for REST only' do
      let_it_be(:ancestor_group) { create(:group, :private, organization: organization) }
      let_it_be(:ancestor_group_milestone) { create(:milestone, group: ancestor_group, updated_at: 2.days.ago) }

      before_all do
        group.update!(parent: ancestor_group)
      end

      context 'when include_ancestors is true' do
        let(:params) { { include_ancestors: true } }

        context 'when user has access to ancestor groups' do
          let(:milestones) { [ancestor_group_milestone, milestone, closed_milestone] }

          before do
            ancestor_group.add_guest(user)
            group.add_guest(user)
          end

          it_behaves_like 'listing all milestones'

          context 'when deprecated include_parent_milestones is true' do
            let(:params) { { include_parent_milestones: true } }

            it_behaves_like 'listing all milestones'
          end

          context 'when both include_parent_milestones and include_ancestors are specified' do
            let(:params) { { include_ancestors: true, include_parent_milestones: true } }

            it 'returns 400' do
              get api(route, user), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'when iids param is present' do
            let(:params) { { include_ancestors: true, iids: [milestone.iid] } }

            it_behaves_like 'listing all milestones'
          end

          context 'when updated_before param is present' do
            let(:params) { { updated_before: 1.day.ago.iso8601, include_ancestors: true } }

            it_behaves_like 'listing all milestones' do
              let(:milestones) { [ancestor_group_milestone, milestone] }
            end
          end

          context 'when updated_after param is present' do
            let(:params) { { updated_after: 1.day.ago.iso8601, include_ancestors: true } }

            it_behaves_like 'listing all milestones' do
              let(:milestones) { [closed_milestone] }
            end
          end
        end

        context 'when user has no access to ancestor groups' do
          let(:user) { create(:user) }

          before do
            # When a group has a project, users that have access to the group will get access to ancestor groups
            # See https://gitlab.com/groups/gitlab-org/-/epics/9424
            group.projects.delete_all

            group.add_guest(user)
          end

          it_behaves_like 'listing all milestones' do
            let(:milestones) { [milestone, closed_milestone] }
          end
        end
      end

      context 'when updated_before param is present' do
        let(:params) { { updated_before: 1.day.ago.iso8601 } }

        it_behaves_like 'listing all milestones' do
          let(:milestones) { [milestone] }
        end
      end

      context 'when updated_after param is present' do
        let(:params) { { updated_after: 1.day.ago.iso8601 } }

        it_behaves_like 'listing all milestones' do
          let(:milestones) { [closed_milestone] }
        end
      end
    end

    context 'for common GraphQL/REST' do
      it_behaves_like 'group milestones including ancestors and descendants'

      def query_group_milestone_ids(params)
        get api(route, current_user), params: params

        json_response.pluck('id')
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

      control = ActiveRecord::QueryRecorder.new { perform_request }

      create(:issue, project: project, milestone: milestone)

      expect { perform_request }.not_to exceed_query_limit(control)
    end
  end

  def setup_for_group
    context_group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    context_group.add_reporter(user)
    public_project.update!(namespace: context_group)
    context_group.reload
  end
end
