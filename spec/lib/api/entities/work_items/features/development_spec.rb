# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Development, feature_category: :portfolio_management do
  describe '#as_json' do
    let(:user) { build_stubbed(:user) }
    let(:closing_merge_requests_counts) { { work_item.id => 3 } }
    let(:will_auto_close_ids) { Set.new([work_item.id]) }
    let(:work_item) { build_stubbed(:work_item) }
    let(:widget) { instance_double(WorkItems::Widgets::Development, work_item: work_item) }

    subject(:representation) do
      described_class.new(
        widget,
        current_user: user,
        closing_merge_requests_counts: closing_merge_requests_counts,
        will_auto_close_ids: will_auto_close_ids
      ).as_json
    end

    it 'exposes the closing merge requests count from the pre-computed counts' do
      expect(representation[:closing_merge_requests_count]).to eq(3)
    end

    context 'when there is no pre-computed count for the work item' do
      let(:closing_merge_requests_counts) { {} }

      it 'returns a zero count' do
        expect(representation[:closing_merge_requests_count]).to eq(0)
      end
    end

    describe 'will_auto_close_by_merge_request' do
      it 'is true when the work item is in the pre-computed will_auto_close set' do
        expect(representation[:will_auto_close_by_merge_request]).to be(true)
      end

      context 'when the work item is not in the set' do
        let(:will_auto_close_ids) { Set.new }

        it 'is false' do
          expect(representation[:will_auto_close_by_merge_request]).to be(false)
        end
      end

      context 'when the will_auto_close_ids option is not provided' do
        subject(:representation) do
          described_class.new(widget, current_user: user).as_json
        end

        it 'is false' do
          expect(representation[:will_auto_close_by_merge_request]).to be(false)
        end
      end
    end
  end
end
