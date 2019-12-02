# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::Pagination do
  subject { Class.new.include(described_class).new }

  describe '#paginate' do
    let(:relation) { double("relation") }
    let(:offset_pagination) { double("offset pagination") }
    let(:expected_result) { double("result") }

    it 'delegates to OffsetPagination' do
      expect(::Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(offset_pagination)
      expect(offset_pagination).to receive(:paginate).with(relation).and_return(expected_result)

      result = subject.paginate(relation)

      expect(result).to eq(expected_result)
    end
  end
end
