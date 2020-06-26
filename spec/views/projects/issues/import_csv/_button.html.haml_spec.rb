# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/import_csv/_button' do
  include Devise::Test::ControllerHelpers

  context 'when the user does not have edit permissions' do
    before do
      render
    end

    it 'shows a dropdown button to import CSV' do
      expect(rendered).to have_text('Import CSV')
    end

    it 'does not show a button to import from Jira' do
      expect(rendered).not_to have_text('Import from Jira')
    end
  end

  context 'when the user has edit permissions' do
    let(:project) { create(:project) }
    let(:current_user) { create(:user, maintainer_projects: [project]) }

    before do
      allow(view).to receive(:project_import_jira_path).and_return('import/jira')
      allow(view).to receive(:current_user).and_return(current_user)

      assign(:project, project)

      render
    end

    it 'shows a dropdown button to import CSV' do
      expect(rendered).to have_text('Import CSV')
    end

    it 'shows a button to import from Jira' do
      expect(rendered).to have_text('Import from Jira')
    end
  end
end
