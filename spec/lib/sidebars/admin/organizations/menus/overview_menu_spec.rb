# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoryBot/AvoidCreate -- render? requires DB records
RSpec.describe Sidebars::Admin::Organizations::Menus::OverviewMenu, feature_category: :navigation do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, owner_of: organization) }

  let(:context) do
    Sidebars::Context.new(current_user: user, container: nil, current_organization: organization)
  end

  subject(:menu) { described_class.new(context) }

  describe '#title' do
    it 'returns the correct title' do
      expect(menu.title).to eq s_('Organization|Organization overview')
    end
  end

  describe '#sprite_icon' do
    it 'returns the correct icon' do
      expect(menu.sprite_icon).to eq 'organization'
    end
  end

  describe '#render?' do
    context 'when user can access organization admin area' do
      it 'renders' do
        expect(menu.render?).to be true
      end
    end

    context 'when user cannot access organization admin area' do
      let(:user) { create(:user) }

      it 'does not render' do
        expect(menu.render?).to be false
      end
    end

    context 'when user is not logged in' do
      let(:user) { nil }

      it 'does not render' do
        expect(menu.render?).to be false
      end
    end

    it 'authorizes against the current organization' do
      expect(menu).to receive(:can?).with(user, :access_organization_admin_area, organization).and_call_original

      menu.render?
    end
  end

  describe '#has_items?' do
    it 'has items' do
      expect(menu.has_items?).to be true
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
