# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_files', feature_category: :groups_and_projects do
  let_it_be(:template) { 'projects/files' }
  let_it_be(:namespace) { build_stubbed(:namespace) }
  let_it_be(:user) { build_stubbed(:user, namespace: namespace) }
  let_it_be(:project) { build_stubbed(:project, namespace: namespace) }

  before do
    assign(:project, project)
    assign(:path, '/job_path')
    assign(:ref, 'main')
    # used by project_new_blob_path
    assign(:id, '1')

    allow(project).to receive(:statistics_buttons).and_return([])
  end

  context 'when the user disabled project shortcut buttons' do
    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(user).to receive(:project_shortcut_buttons).and_return(false)
    end

    it 'does not render buttons' do
      render(template, is_project_overview: true)

      expect(rendered).not_to have_selector('.js-show-on-project-root')
    end
  end

  context 'when the user has project shortcut buttons enabled' do
    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(user).to receive(:project_shortcut_buttons).and_return(true)

      stub_feature_flags(project_overview_reorg: false)
    end

    it 'renders buttons' do
      render(template, is_project_overview: true)

      expect(rendered).to have_selector('.js-show-on-project-root')
    end
  end

  context 'when rendered in the project overview page and there is no current user' do
    before do
      stub_feature_flags(project_overview_reorg: false)
    end

    it 'renders buttons' do
      render(template, is_project_overview: true)

      expect(rendered).to have_selector('.js-show-on-project-root')
    end
  end

  context 'when rendered in a page other than project overview' do
    it 'does not render buttons' do
      render(template, is_project_overview: false)

      expect(rendered).not_to have_selector('.js-show-on-project-root')
    end
  end
end
