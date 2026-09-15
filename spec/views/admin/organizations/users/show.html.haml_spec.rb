# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/organizations/users/show.html.haml', :with_current_organization, feature_category: :organization do
  let_it_be(:user) { build_stubbed(:user, :with_namespace) }

  let(:current_user) { build_stubbed(:admin) }
  let(:page) { Nokogiri::HTML.parse(rendered) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(current_user)
  end

  it 'shows only the basic user details' do
    render

    expect(page.at(%([data-testid="user-id-content"]))).to have_text user.id.to_s
    expect(rendered).to have_text 'Namespace ID:'
    expect(rendered).to have_text 'Name:'
    expect(rendered).to have_text 'Username:'
  end

  it 'shows the account summary with the profile page' do
    render

    expect(rendered).to have_text 'Profile page:'
    expect(rendered).to have_link user.username, href: user_path(user)
  end
end
