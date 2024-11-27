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
      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'List' do
      let(:item_id) { :issue_list }

      it { is_expected.not_to be_nil }

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

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(menu.pill_count_field).to eq('openIssuesCount')
    end

    context 'when async_sidebar_counts feature flag is disabled' do
      before do
        stub_feature_flags(async_sidebar_counts: false)
      end

      it 'returns nil' do
        expect(menu.pill_count_field).to be_nil
      end
    end
  end

  context 'when count query times out' do
    let(:count_service) { ::Groups::OpenIssuesCountService }

    before do
      stub_feature_flags(async_sidebar_counts: false)

      allow_next_instance_of(count_service) do |service|
        allow(service).to receive(:count).and_raise(ActiveRecord::QueryCanceled)
      end
    end

    it 'logs the error and returns a null count' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
        ActiveRecord::QueryCanceled, group_id: group.id, query: 'group_sidebar_issues_count'
      ).and_call_original

      expect(menu.pill_count).to be_nil
    end
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :group_issue_list,
        active_routes: { path: 'groups#issues' },
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::PlanMenu
      }
    end
  end
end
