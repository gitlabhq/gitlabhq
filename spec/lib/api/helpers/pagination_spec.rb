# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::Pagination do
  subject { Class.new.include(described_class).new }

  let(:expected_result) { double("result", to_a: double) }
  let(:relation) { double("relation") }
  let(:params) { {} }

  before do
    allow(subject).to receive(:params).and_return(params)
  end

  describe '#paginate' do
    let(:offset_pagination) { double("offset pagination") }

    it 'delegates to OffsetPagination' do
      expect(::Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(offset_pagination)
      expect(offset_pagination).to receive(:paginate).with(relation).and_return(expected_result)

      result = subject.paginate(relation)

      expect(result).to eq(expected_result)
    end
  end

  describe '#paginate_and_retrieve!' do
    context 'for offset pagination' do
      before do
        allow(Gitlab::Pagination::Keyset).to receive(:available?).and_return(false)
      end

      it 'delegates to paginate' do
        expect(subject).to receive(:paginate).with(relation).and_return(expected_result)

        result = subject.paginate_and_retrieve!(relation)

        expect(result).to eq(expected_result.to_a)
      end
    end

    context 'for keyset pagination' do
      let(:params) { { pagination: 'keyset' } }
      let(:request_context) { double('request context') }

      before do
        allow(Gitlab::Pagination::Keyset::RequestContext).to receive(:new).with(subject).and_return(request_context)
      end

      context 'when keyset pagination is available' do
        it 'delegates to KeysetPagination' do
          expect(Gitlab::Pagination::Keyset).to receive(:available?).and_return(true)
          expect(Gitlab::Pagination::Keyset).to receive(:paginate).with(request_context, relation).and_return(expected_result)

          result = subject.paginate_and_retrieve!(relation)

          expect(result).to eq(expected_result.to_a)
        end
      end

      context 'when keyset pagination is not available' do
        it 'renders a 501 error if keyset pagination isnt available yet' do
          expect(Gitlab::Pagination::Keyset).to receive(:available?).with(request_context, relation).and_return(false)
          expect(Gitlab::Pagination::Keyset).not_to receive(:paginate)
          expect(subject).to receive(:error!).with(/not yet available/, 405)

          subject.paginate_and_retrieve!(relation)
        end
      end
    end
  end
end
