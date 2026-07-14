# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::CustomerRelationsMenu, feature_category: :navigation do
  let(:group) { build_stubbed(:group, :private) }
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe 'Menu Items' do
    subject { menu.renderable_items.index { |e| e.item_id == :crm_contacts } }

    context 'when the user can read CRM contacts' do
      before do
        stub_member_access_level(group, owner: user)
      end

      it { is_expected.not_to be_nil }
    end

    context 'when the user does not have access' do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe 'Feature Library metadata' do
    before do
      stub_member_access_level(group, owner: user)
    end

    it 'gives every item a description and a unique library_icon', :aggregate_failures do
      serialized = menu.renderable_items.map(&:serialize_for_super_sidebar)

      expect(serialized).not_to be_empty
      expect(serialized).to all(include(:description, :library_icon))
      icons = serialized.map { |item| item[:library_icon] }
      expect(icons).to match_array(icons.uniq)
    end
  end
end
