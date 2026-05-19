# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::GraphqlCursorBuilder, feature_category: :api do
  describe '.build' do
    let(:converter) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter }
    let(:before_cursor) { nil }
    let(:after_cursor) { nil }
    let(:base_cursor) { converter.dump(severity: 'low', id: '42') }

    subject(:cursor) { described_class.build(after: after_cursor, before: before_cursor) }

    context 'when :after is given' do
      let(:after_cursor) { base_cursor }

      it 'tags the cursor with the forward direction and preserves the payload' do
        decoded = converter.parse(cursor)

        expect(decoded[:_kd]).to eq(Gitlab::Pagination::Keyset::Paginator::FORWARD_DIRECTION)
        expect(decoded.slice(:severity, :id)).to eq('severity' => 'low', 'id' => '42')
      end
    end

    context 'when :before is given' do
      let(:before_cursor) { base_cursor }

      it 'tags the cursor with the backward direction and preserves the payload' do
        decoded = converter.parse(cursor)

        expect(decoded[:_kd]).to eq(Gitlab::Pagination::Keyset::Paginator::BACKWARD_DIRECTION)
        expect(decoded.slice(:severity, :id)).to eq('severity' => 'low', 'id' => '42')
      end
    end

    context 'when both :after and :before are given' do
      let(:after_cursor) { base_cursor }
      let(:before_cursor) { converter.dump(severity: 'high', id: '7') }

      it 'prefers :after' do
        decoded = converter.parse(cursor)

        expect(decoded[:_kd]).to eq(Gitlab::Pagination::Keyset::Paginator::FORWARD_DIRECTION)
        expect(decoded.slice(:severity, :id)).to eq('severity' => 'low', 'id' => '42')
      end
    end

    context 'when neither :after nor :before is given' do
      it { is_expected.to be_nil }
    end
  end
end
