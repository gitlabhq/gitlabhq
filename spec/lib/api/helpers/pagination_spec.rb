# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::Pagination do
  subject { Class.new.include(described_class).new }

  describe '#paginate' do
    let(:relation) { double("relation") }
    let(:offset_pagination) { double("offset pagination") }
    let(:expected_result) { double("result") }

    before do
      allow(subject).to receive(:params).and_return(params)
    end

    context 'for offset pagination' do
      let(:params) { {} }

      it 'delegates to OffsetPagination' do
        expect(::Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(offset_pagination)
        expect(offset_pagination).to receive(:paginate).with(relation).and_return(expected_result)

        result = subject.paginate(relation)

        expect(result).to eq(expected_result)
      end
    end

    context 'for keyset pagination' do
      let(:params) { { pagination: 'keyset' } }
      let(:request_context) { double('request context') }

      before do
        allow(Gitlab::Pagination::Keyset::RequestContext).to receive(:new).with(subject).and_return(request_context)
        allow(Gitlab::Pagination::Keyset).to receive(:available?).and_return(true)
      end

      it 'delegates to KeysetPagination' do
        expect(Gitlab::Pagination::Keyset).to receive(:paginate).with(request_context, relation).and_return(expected_result)

        result = subject.paginate(relation)

        expect(result).to eq(expected_result)
      end

      it 'renders a 501 error if keyset pagination isnt available yet' do
        expect(Gitlab::Pagination::Keyset).to receive(:available?).with(request_context, relation).and_return(false)
        expect(Gitlab::Pagination::Keyset).not_to receive(:paginate)
        expect(subject).to receive(:error!).with(/not yet available/, 501)

        subject.paginate(relation)
      end
    end
  end
end
