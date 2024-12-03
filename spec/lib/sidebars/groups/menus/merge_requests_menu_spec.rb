# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::MergeRequestsMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    context 'when user can read merge requests' do
      it 'returns true' do
        expect(menu.render?).to eq true
      end
    end

    context 'when user cannot read merge requests' do
      let(:user) { nil }

      it 'returns false' do
        expect(menu.render?).to eq false
      end
    end
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :group_merge_request_list,
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::CodeMenu
      }
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(menu.pill_count_field).to eq('openMergeRequestsCount')
    end
  end
end
