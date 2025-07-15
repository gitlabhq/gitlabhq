# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/_head.html.haml', feature_category: :user_management do
  let(:user) { build(:user) }
  let(:user_member_role) { build_stubbed(:user_member_role, user: user) }

  before do
    assign(:user, user)
  end

  context 'when the user is a LDAP user' do
    it 'shows LDAP badge' do
      allow(user).to receive(:ldap_user?).and_return(true)
      render

      expect(rendered).to have_css('.badge-info', text: 'LDAP')
    end
  end

  context 'when the user is not a LDAP user' do
    it 'does not show LDAP badge' do
      allow(user).to receive(:ldap_user?).and_return(false)
      render

      expect(rendered).not_to have_css('.badge-info', text: 'LDAP')
    end
  end
end
