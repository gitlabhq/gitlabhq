# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/organizations/users/_head.html.haml', :with_current_organization, feature_category: :organization do
  let(:user) { build(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
  end

  shared_examples 'renders only the Account tab' do
    it 'renders the Account tab' do
      render

      expect(rendered).to have_link('Account')
    end

    it 'does not render the other instance admin tabs' do
      render

      expect(rendered).not_to have_link('Groups and projects')
      expect(rendered).not_to have_link('SSH keys')
      expect(rendered).not_to have_link('Identities')
    end
  end

  it_behaves_like 'renders only the Account tab'

  context 'when the current user can admin all resources' do
    before do
      allow(view).to receive(:current_user).and_return(build_stubbed(:admin))
      allow(view).to receive(:can?).and_call_original
      allow(view).to receive(:can?).with(anything, :admin_all_resources).and_return(true)
    end

    it_behaves_like 'renders only the Account tab'
  end
end
