require 'spec_helper'

describe 'dashboard/projects/_blank_state_admin_welcome.html.haml' do
  let(:user) { create(:admin) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'links to new group path' do
    render

    expect(rendered).to have_link('Create a group', href: new_group_path)
  end
end
