# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::MergeRequestsMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  include_examples 'menu item shows pill based on count', :assigned_open_merge_requests_count

  describe 'submenu items' do
    using RSpec::Parameterized::TableSyntax

    where(:order, :title, :key) do
      0 | 'Assigned' | :assigned
      1 | 'Review requests' | :review_requested
    end

    with_them do
      let(:item) { subject.renderable_items[order] }

      it 'renders items in the right order' do
        expect(item.title).to eq title
      end

      context 'when there are no MR counts' do
        before do
          allow(user).to receive(:assigned_open_merge_requests_count).and_return(0)
          allow(user).to receive(:review_requested_open_merge_requests_count).and_return(0)
        end

        it 'shows a pill even though count is zero' do
          expect(item.has_pill?).to eq true
          expect(item.pill_count).to eq 0
        end
      end

      context 'when there are MR counts' do
        let(:non_zero_counts) { { assigned: 2, review_requested: 3 } }

        before do
          allow(user).to receive(:assigned_open_merge_requests_count).and_return(non_zero_counts[:assigned])
          allow(user).to receive(:review_requested_open_merge_requests_count)
            .and_return(non_zero_counts[:review_requested])
        end

        it 'shows a pill with the correct count' do
          expect(item.has_pill?).to eq true
          expect(item.pill_count).to eq non_zero_counts[key]
        end
      end
    end
  end
end
