# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::WorkItemsMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject(:menu) { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :project_issue_list,
        active_routes: { path: %w[
          projects/issues#index projects/issues#show projects/issues#new
          projects/work_items#index projects/work_items#show projects/work_items#new
        ] },
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::PlanMenu,
        badge: menu.send(:work_items_badge)
      }
    end
  end

  describe '#render?' do
    context 'when user can read issues' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot read issues' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when issues feature is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq false
      end
    end

    context 'when issue feature is disabled' do
      it 'returns false' do
        allow(project).to receive(:issues_enabled?).and_return(false)

        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(subject.pill_count_field).to eq('openIssuesCount')
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

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Service Desk' do
      let(:item_id) { :service_desk }

      describe 'when service desk is supported' do
        before do
          allow(::ServiceDesk).to receive(:supported?).and_return(true)
        end

        describe 'when service desk is enabled' do
          before do
            project.update!(service_desk_enabled: true)
          end

          it { is_expected.not_to be_nil }
        end

        describe 'when service desk is disabled' do
          before do
            project.update!(service_desk_enabled: false)
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'when service desk is unsupported' do
        before do
          allow(::ServiceDesk).to receive(:supported?).and_return(false)
          project.update!(service_desk_enabled: true)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#show_work_items_badge?' do
    subject { menu.send(:show_work_items_badge?) }

    describe 'when user is not logged in' do
      let(:user) { nil }

      it { is_expected.to be(false) }
    end

    describe 'when user is logged in' do
      it 'does not show the badge when the work_items_saved_views flag is disabled' do
        allow(project).to receive(:work_items_saved_views_enabled?).with(user).and_return(false)
        expect(menu.send(:show_work_items_badge?)).to be(false)
      end

      it 'does not show the badge when user has dismissed the callout' do
        allow(project).to receive(:work_items_saved_views_enabled?).with(user).and_return(true)
        allow(user).to receive(:dismissed_callout?).with(feature_name: 'work_items_nav_badge').and_return(true)
        expect(menu.send(:show_work_items_badge?)).to be(false)
      end

      describe 'when the work_items_saved_views flag is enabled and callout not dismissed' do
        before do
          allow(project).to receive(:work_items_saved_views_enabled?).with(user).and_return(true)
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
end
