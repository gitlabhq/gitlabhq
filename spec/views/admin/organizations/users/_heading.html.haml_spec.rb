# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/organizations/users/_heading.html.haml', :with_current_organization, feature_category: :organization do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
  end

  context 'when the current user can edit the organization user' do
    before do
      allow(view).to receive(:can_edit_organization_user?).with(user).and_return(true)
    end

    it 'renders the Edit button' do
      render

      expect(rendered).to have_link('Edit', href: edit_admin_user_path(user))
    end
  end

  context 'when the current user cannot edit the organization user' do
    before do
      allow(view).to receive(:can_edit_organization_user?).with(user).and_return(false)
    end

    it 'does not render the Edit button' do
      render

      expect(rendered).not_to have_link('Edit')
    end
  end
end
