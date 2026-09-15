# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Graphql::MergeRequests::DiffsArray, feature_category: :code_review_workflow do
  it 'defaults overflow to nil and preserves cursors and elements', :aggregate_failures do
    array = described_class.new('prev', 'next', :a, :b, has_next_page: true)

    expect(array.to_a).to match_array([:a, :b])
    expect(array.start_cursor).to eq('prev')
    expect(array.end_cursor).to eq('next')
    expect(array.has_next_page).to be(true)
    expect(array.overflow).to be_nil
  end

  it 'stores the overflow flag' do
    array = described_class.new('prev', 'next', :a, overflow: true)

    expect(array.overflow).to be(true)
  end
end
