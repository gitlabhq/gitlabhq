# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::PaginationStrategies do
  subject { Class.new.include(described_class).new }

  let(:expected_result) { double("result") }
  let(:relation) { double("relation") }
  let(:params) { {} }

  before do
    allow(subject).to receive(:params).and_return(params)
  end

  describe '#paginate_with_strategies' do
    let(:paginator) { double("paginator", paginate: expected_result, finalize: nil) }

    before do
      allow(subject).to receive(:paginator).with(relation).and_return(paginator)
    end

    it 'yields paginated relation' do
      expect { |b| subject.paginate_with_strategies(relation, &b) }.to yield_with_args(expected_result)
    end

    it 'calls #finalize with first value returned from block' do
      return_value = double
      expect(paginator).to receive(:finalize).with(return_value)

      subject.paginate_with_strategies(relation) do |records|
        some_options = {}
        [return_value, some_options]
      end
    end

    it 'returns whatever the block returns' do
      return_value = [double, double]

      result = subject.paginate_with_strategies(relation) do |records|
        return_value
      end

      expect(result).to eq(return_value)
    end
  end

  describe '#paginator' do
    context 'offset pagination' do
      let(:paginator) { double("paginator") }

      before do
        allow(subject).to receive(:keyset_pagination_enabled?).and_return(false)
      end

      it 'delegates to OffsetPagination' do
        expect(Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(paginator)

        expect(subject.paginator(relation)).to eq(paginator)
      end
    end

    context 'for keyset pagination' do
      let(:params) { { pagination: 'keyset' } }
      let(:request_context) { double('request context') }
      let(:pager) { double('pager') }

      before do
        allow(subject).to receive(:keyset_pagination_enabled?).and_return(true)
        allow(Gitlab::Pagination::Keyset::RequestContext).to receive(:new).with(subject).and_return(request_context)
      end

      context 'when keyset pagination is available' do
        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available?).and_return(true)
          allow(Gitlab::Pagination::Keyset::Pager).to receive(:new).with(request_context).and_return(pager)
        end

        it 'delegates to Pager' do
          expect(subject.paginator(relation)).to eq(pager)
        end
      end

      context 'when keyset pagination is not available' do
        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available?).with(request_context, relation).and_return(false)
        end

        it 'renders a 501 error' do
          expect(subject).to receive(:error!).with(/not yet available/, 405)

          subject.paginator(relation)
        end
      end
    end
  end
end
