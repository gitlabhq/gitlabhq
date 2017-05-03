require 'spec_helper'

describe 'projects/edit' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:empty_project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(current_user: user, can?: true)
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  context 'LFS enabled setting' do
    it 'displays the correct elements' do
      render
      expect(rendered).to have_select('project_lfs_enabled')
      expect(rendered).to have_content('Git Large File Storage')
    end
  end
end
