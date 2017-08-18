require 'spec_helper'

describe 'projects/edit' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(current_user: user, can?: true)
  end

  context 'LFS enabled setting' do
    it 'displays the correct elements' do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

      render

      expect(rendered).to have_select('project_lfs_enabled')
      expect(rendered).to have_content('Git Large File Storage')
    end
  end

  context 'project export disabled' do
    it 'does not display the project export option' do
      stub_application_setting(project_export_enabled?: false)

      render

      expect(rendered).not_to have_content('Export project')
    end
  end
end
