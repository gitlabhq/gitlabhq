# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::Rugged, :request_store do
  subject { described_class.new }

  let(:project) { create(:project) }

  before do
    allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  it 'returns no results' do
    expect(subject.results).to eq({})
  end

  it 'returns aggregated results' do
    ::Gitlab::RuggedInstrumentation.add_query_time(1.234)
    ::Gitlab::RuggedInstrumentation.increment_query_count
    ::Gitlab::RuggedInstrumentation.increment_query_count

    ::Gitlab::RuggedInstrumentation.add_call_details(feature: :rugged_test,
                                                     args: [project.repository.raw, 'HEAD'],
                                                     duration: 0.123)
    ::Gitlab::RuggedInstrumentation.add_call_details(feature: :rugged_test2,
                                                     args: [project.repository, 'refs/heads/master'],
                                                     duration: 0.456)

    results = subject.results
    expect(results[:calls]).to eq(2)
    expect(results[:duration]).to eq('1234.00ms')
    expect(results[:details].count).to eq(2)

    expected = [
      [project.repository.raw.to_s, "HEAD"],
      [project.repository.to_s, "refs/heads/master"]
    ]

    expect(results[:details].map { |data| data[:args] }).to match_array(expected)
  end
end
