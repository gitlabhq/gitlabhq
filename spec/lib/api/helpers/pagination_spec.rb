# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::Pagination do
  subject { Class.new.include(described_class).new }

  let(:paginator) { double('paginator') }
  let(:relation) { double('relation') }
  let(:expected_result) { double('expected result') }

  it 'delegates to OffsetPagination' do
    expect(Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(paginator)
    expect(paginator).to receive(:paginate).with(relation).and_return(expected_result)

    expect(subject.paginate(relation)).to eq(expected_result)
  end
end
