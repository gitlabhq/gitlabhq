# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/project_members/index', :aggregate_failures, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project, :empty_repo, :with_namespace_settings).present(current_user: user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate

  before do
    allow(view).to receive(:project_members_app_data_json).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:project, project)
  end

  context 'when user can invite members for the project' do
    before do
      project.add_maintainer(user)
    end

    context 'when modal is enabled' do
      it 'renders as expected' do
        render

        expect(rendered).to have_content('Project members')
        expect(rendered).to have_content('You can invite a new member')
        expect(rendered).to have_selector('.js-import-project-members-trigger')
        expect(rendered).to have_selector('.js-import-project-members-modal')
        expect(rendered).to have_selector('.js-invite-group-trigger')
        expect(rendered).to have_selector('.js-invite-members-trigger')
        expect(rendered).not_to have_content('Members can be added by project')
      end

      context 'when project is not allowed to share with group' do
        before do
          project.namespace.share_with_group_lock = true
        end

        it 'renders as expected' do
          render

          expect(rendered).not_to have_selector('.js-invite-group-trigger')
        end
      end
    end
  end

  context 'when user can not invite members or group for the project' do
    context 'when project can be shared' do
      it 'renders as expected', :aggregate_failures do
        render

        expect(rendered).to have_content('Project members')
        expect(rendered).not_to have_content('You can invite a new member')
        expect(rendered).not_to have_selector('.js-import-project-members-trigger')
        expect(rendered).not_to have_selector('.js-import-project-members-modal')
        expect(rendered).not_to have_selector('.js-invite-group-trigger')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
        expect(rendered).to have_content('Members can be added by project')
        expect(response).not_to render_template(partial: 'projects/_invite_members_modal')
      end
    end
  end
end
