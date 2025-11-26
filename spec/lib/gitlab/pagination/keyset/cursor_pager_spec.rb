# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::CursorPager, feature_category: :database do
  let(:relation) { Group.all.order(:name, :id) }
  let(:per_page) { 3 }
  let(:request_context) { double('request_context', params: params) }
  let(:cursor_based_request_context) { Gitlab::Pagination::Keyset::CursorBasedRequestContext.new(request_context) }

  before_all do
    create_list(:group, 7)
  end

  describe '#paginate' do
    let(:params) { { cursor: nil, per_page: per_page } }

    subject(:paginated_result) { described_class.new(cursor_based_request_context).paginate(relation) }

    it 'returns the limited relation' do
      expect(paginated_result).to eq(relation.limit(per_page))
    end
  end

  describe '#finalize' do
    let(:base_params) { { cursor: nil, per_page: per_page } }
    let(:cursor_for_previous_page) { relation.keyset_paginate(**params).cursor_for_previous_page }
    let(:cursor_for_next_page) { relation.keyset_paginate(**params).cursor_for_next_page }

    subject(:finalize) do
      service = described_class.new(cursor_based_request_context)
      # we need to do this because `finalize` can only be called
      # after `paginate` is called. Otherwise the `paginator` object won't be set.
      service.paginate(relation)
      service.finalize
    end

    context 'when retrieving the first page' do
      let(:params) do
        { cursor: relation.keyset_paginate(**base_params).cursor_for_first_page, per_page: per_page }
      end

      it 'passes information about next page to request' do
        expect_next_instance_of(Gitlab::Pagination::Keyset::HeaderBuilder, request_context) do |builder|
          expect(builder).to receive(:add_next_page_header).once.with({ cursor: cursor_for_next_page })
          expect(builder).to receive(:add_prev_and_next_cursor_headers).once.with(nil, cursor_for_next_page)
        end

        finalize
      end
    end

    context 'when retrieving the last page' do
      let(:params) do
        { cursor: relation.keyset_paginate(**base_params).cursor_for_last_page, per_page: per_page }
      end

      it 'only passes information about the previous page to request' do
        expect_next_instance_of(Gitlab::Pagination::Keyset::HeaderBuilder, request_context) do |builder|
          expect(builder).not_to receive(:add_next_page_header)
          expect(builder).to receive(:add_prev_and_next_cursor_headers).once.with(cursor_for_previous_page, nil)
        end

        finalize
      end
    end

    context 'when retrieving a middle page' do
      let(:params) do
        { cursor: relation.keyset_paginate(**base_params).cursor_for_next_page, per_page: per_page }
      end

      it 'passes information about the previous and next page to request' do
        expected_params = [cursor_for_previous_page, cursor_for_next_page]
        expect_next_instance_of(Gitlab::Pagination::Keyset::HeaderBuilder, request_context) do |builder|
          expect(builder).to receive(:add_prev_and_next_cursor_headers).once.with(*expected_params)
          expect(builder).to receive(:add_next_page_header).once.with({ cursor: cursor_for_next_page })
        end

        finalize
      end
    end

    context 'when retrieving an empty page' do
      let(:params) { base_params }
      let(:relation) { Group.where('id > ?', Group.maximum(:id) + 1).order(:name, :id) }

      it 'does not build information about the next page' do
        expect(Gitlab::Pagination::Keyset::HeaderBuilder).not_to receive(:new)

        finalize
      end
    end
  end
end
