# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/milestones/_milestone.html.haml', feature_category: :team_planning do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Necessary to check authorization
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user, developer_of: [group]) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:release) { create(:release, project: project, milestones: [milestone]) }
  let_it_be(:unauthorized_user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:current_user) { developer }

  describe 'release information' do
    before do
      render 'shared/milestones/milestone',
        issues_path: issues_group_path(group),
        merge_requests_path: merge_requests_group_path(group),
        milestone: milestone,
        current_user: current_user
    end

    it 'renders recent releases' do
      expect(rendered).to include(release.name)
    end

    context 'when user does not have access to the release' do
      let(:current_user) { unauthorized_user }

      it 'does not render release information' do
        expect(rendered).not_to include(release.name)
      end
    end
  end
end
