# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoryBot/AvoidCreate -- render? requires DB records
RSpec.describe Sidebars::Admin::Organizations::Menus::SettingsMenu, feature_category: :navigation do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, owner_of: organization) }

  let(:context) do
    Sidebars::Context.new(current_user: user, container: nil, current_organization: organization)
  end

  subject(:menu) { described_class.new(context) }

  describe '#title' do
    it 'returns the correct title' do
      expect(menu.title).to eq _('Settings')
    end
  end

  describe '#sprite_icon' do
    it 'returns the correct icon' do
      expect(menu.sprite_icon).to eq 'settings'
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

  describe 'menu items' do
    it 'includes the General item' do
      general_item = menu.renderable_items.find { |item| item.item_id == :organization_admin_settings_general }

      expect(general_item).to be_present
      expect(general_item.title).to eq(_('General'))
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
