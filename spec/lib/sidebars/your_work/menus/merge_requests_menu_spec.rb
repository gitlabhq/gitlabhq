# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::MergeRequestsMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject(:menu) { described_class.new(context) }

  it 'has correct pill settings' do
    expect(menu.has_pill?).to be true
    expect(menu.pill_count_field).to eq("total_merge_requests")
  end

  describe 'submenu items' do
    using RSpec::Parameterized::TableSyntax

    where(:order, :title, :key, :count_field) do
      0 | 'Assigned' | :assigned | 'assigned_merge_requests'
      1 | 'Review requests' | :review_requested | 'review_requested_merge_requests'
    end

    with_them do
      let(:item) { menu.renderable_items[order] }

      it 'renders items in the right order' do
        expect(item.title).to eq title
      end

      it 'has correct pill settings' do
        expect(item.has_pill?).to be true
        expect(item.pill_count_field).to eq(count_field)
      end
    end
  end
end
