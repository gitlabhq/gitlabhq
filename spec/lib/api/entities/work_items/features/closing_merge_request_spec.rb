# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::ClosingMergeRequest, feature_category: :portfolio_management do
  describe '#as_json' do
    let(:user) { build_stubbed(:user) }
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:closing_row) do
      build_stubbed(:merge_requests_closing_issues, merge_request: merge_request, from_mr_description: true)
    end

    let(:closing_rows_by_mr_id) { { merge_request.id => closing_row } }

    subject(:representation) do
      described_class.new(
        merge_request,
        current_user: user,
        closing_rows_by_mr_id: closing_rows_by_mr_id
      ).as_json
    end

    it 'exposes the closing-issue row id rather than the merge request id' do
      expect(representation[:id]).to eq(closing_row.id)
      expect(representation[:id]).not_to eq(merge_request.id)
    end

    it 'exposes from_mr_description from the looked-up row' do
      expect(representation[:from_mr_description]).to be(true)
    end

    it 'exposes the merge request itself' do
      expect(representation[:merge_request]).to include(id: merge_request.id, iid: merge_request.iid)
    end

    context 'when the row is from_mr_description: false' do
      let(:closing_row) do
        build_stubbed(:merge_requests_closing_issues, merge_request: merge_request, from_mr_description: false)
      end

      it 'exposes false' do
        expect(representation[:from_mr_description]).to be(false)
      end
    end

    # The endpoint queries the merge requests by the same ids it builds the lookup from, so a missing
    # row should not happen. Degrade to nil instead of raising if that invariant is ever broken.
    context 'when there is no row for the merge request' do
      let(:closing_rows_by_mr_id) { {} }

      it 'exposes nil for the row-derived fields without raising', :aggregate_failures do
        expect { representation }.not_to raise_error
        expect(representation[:id]).to be_nil
        expect(representation[:from_mr_description]).to be_nil
      end
    end

    context 'when the closing_rows_by_mr_id option is not provided' do
      subject(:representation) { described_class.new(merge_request, current_user: user).as_json }

      it 'exposes nil for the row-derived fields without raising', :aggregate_failures do
        expect { representation }.not_to raise_error
        expect(representation[:id]).to be_nil
        expect(representation[:from_mr_description]).to be_nil
      end
    end
  end
end
