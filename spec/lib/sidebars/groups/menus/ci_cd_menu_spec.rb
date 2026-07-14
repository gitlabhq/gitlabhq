# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::CiCdMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:root_group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { root_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Runners' do
      let(:item_id) { :runners }

      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end
  end

  describe 'Feature Library metadata' do
    it 'gives every item a description and a unique library_icon', :aggregate_failures do
      serialized = described_class.new(context).renderable_items.map(&:serialize_for_super_sidebar)

      expect(serialized).to all(include(:description, :library_icon))
      icons = serialized.map { |item| item[:library_icon] }
      expect(icons).to match_array(icons.uniq)
    end
  end
end
