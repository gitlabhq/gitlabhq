# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::Keyset::LastItems do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:scope) { MergeRequest.order_merged_at_asc }

  subject { described_class.take_items(*args) }

  context 'when the `count` parameter is nil' do
    let(:args) { [scope, nil] }

    it 'returns a single record' do
      expect(subject).to eq(merge_request)
    end
  end

  context 'when the `count` parameter is given' do
    let(:args) { [scope, 1] }

    it 'returns an array' do
      expect(subject).to eq([merge_request])
    end
  end
end
