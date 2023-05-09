# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::IssuesMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe 'Menu Items' do
    subject { menu.renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'menu access rights' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'List' do
      let(:item_id) { :issue_list }

      specify { is_expected.not_to be_nil }

      it_behaves_like 'menu access rights'
    end

    describe 'Boards' do
      let(:item_id) { :boards }

      it_behaves_like 'menu access rights'
    end

    describe 'Milestones' do
      let(:item_id) { :milestones }

      it_behaves_like 'menu access rights'
    end
  end

  it_behaves_like 'pill_count formatted results' do
    let(:count_service) { ::Groups::OpenIssuesCountService }
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :group_issue_list,
        active_routes: { path: 'groups#issues' },
        pill_count: menu.pill_count,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::PlanMenu
      }
    end
  end
end
