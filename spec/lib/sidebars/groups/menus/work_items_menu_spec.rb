# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::WorkItemsMenu, feature_category: :navigation do
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
      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        it 'does not include item' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, policy, group).and_return(false)

          is_expected.to be_nil
        end
      end
    end

    describe 'List' do
      let(:item_id) { :issue_list }
      let(:policy) { :read_group_issues }

      it { is_expected.not_to be_nil }

      it_behaves_like 'menu access rights'
    end

    describe 'Boards' do
      let(:item_id) { :boards }
      let(:policy) { :read_group_boards }

      it_behaves_like 'menu access rights'
    end

    describe 'Milestones' do
      let(:item_id) { :milestones }
      let(:policy) { :read_group_milestones }

      it_behaves_like 'menu access rights'
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(menu.pill_count_field).to eq('openIssuesCount')
    end
  end

  describe '#pill_html_options' do
    it 'returns the pill options' do
      expect(menu.pill_html_options).to eq({ class: 'issue_counter' })
    end
  end

  describe '#sprite_icon' do
    subject { menu.sprite_icon }

    it { is_expected.to eq 'issues' }
  end

  describe '#show_work_items_badge?' do
    subject { menu.send(:show_work_items_badge?) }

    describe 'when user is not logged in' do
      let(:user) { nil }

      it { is_expected.to be(false) }
    end

    describe 'when user is logged in' do
      it 'does not show the badge when the work_items_saved_views flag is disabled' do
        allow(group).to receive(:work_items_saved_views_enabled?).with(user).and_return(false)
        expect(menu.send(:show_work_items_badge?)).to be(false)
      end

      it 'does not show the badge when user has dismissed the callout' do
        allow(group).to receive(:work_items_saved_views_enabled?).with(user).and_return(true)
        allow(user).to receive(:dismissed_callout?).with(feature_name: 'work_items_nav_badge').and_return(true)

        expect(menu.send(:show_work_items_badge?)).to be(false)
      end

      describe 'when work_items_saved_views flag is enabled and the callout is not dismissed' do
        before do
          allow(group).to receive(:work_items_saved_views_enabled?).with(user).and_return(true)
          allow(user).to receive(:dismissed_callout?).with(feature_name: 'work_items_nav_badge').and_return(false)
        end

        it 'does not show the badge after the expiry date' do
          travel_to(Sidebars::Concerns::ShowWorkItemsBadge::WORK_ITEMS_BADGE_EXPIRES_ON + 1.day) do
            expect(menu.send(:show_work_items_badge?)).to be(false)
          end
        end

        it 'shows the badge before the expiry date' do
          travel_to(Sidebars::Concerns::ShowWorkItemsBadge::WORK_ITEMS_BADGE_EXPIRES_ON - 1.day) do
            expect(menu.send(:show_work_items_badge?)).to be(true)
          end
        end
      end
    end
  end

  describe '#work_items_badge_tooltip_text' do
    before do
      allow(group).to receive(:work_items_saved_views_enabled?).with(user).and_return(true)
      allow(group).to receive(:licensed_feature_available?).and_call_original
    end

    it 'contains correct text when epics feature is available' do
      allow(group).to receive(:licensed_feature_available?).with(:epics).and_return(true)
      expect(menu.send(:work_items_badge_tooltip_text)).to eq('Epics and issues are now work items.')
    end

    it 'contains correct text when epics feature is not available' do
      allow(group).to receive(:licensed_feature_available?).with(:epics).and_return(false)
      expect(menu.send(:work_items_badge_tooltip_text)).to eq('Issues are now work items.')
    end
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :group_issue_list,
        active_routes: { path: %w[
          groups/issues#index groups/issues#show groups/issues#new
          groups/work_items#index groups/work_items#show groups/work_items#new
        ] },
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::PlanMenu,
        badge: menu.send(:work_items_badge)
      }
    end
  end
end
