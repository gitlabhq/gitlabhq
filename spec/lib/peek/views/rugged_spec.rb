# frozen_string_literal: true

require 'spec_helper'

describe Peek::Views::Rugged, :request_store do
  subject { described_class.new }

  let(:project) { create(:project) }

  before do
    allow(Gitlab::RuggedInstrumentation).to receive(:peek_enabled?).and_return(true)
  end

  it 'returns no results' do
    expect(subject.results).to eq({})
  end

  it 'returns aggregated results' do
    ::Gitlab::RuggedInstrumentation.query_time += 1.234
    ::Gitlab::RuggedInstrumentation.increment_query_count
    ::Gitlab::RuggedInstrumentation.increment_query_count

    ::Gitlab::RuggedInstrumentation.add_call_details(feature: :rugged_test,
                                                     args: [project.repository.raw, 'HEAD'],
                                                     duration: 0.123)
    ::Gitlab::RuggedInstrumentation.add_call_details(feature: :rugged_test2,
                                                     args: [project.repository.raw, 'refs/heads/master'],
                                                     duration: 0.456)

    expect(subject.duration).to be_within(0.00001).of(1.234)
    expect(subject.calls).to eq(2)

    results = subject.results
    expect(results[:calls]).to eq(2)
    expect(results[:duration]).to eq('1234.00ms')
    expect(results[:details].count).to eq(2)

    expect(results[:details][0][:args]).to eq([project.repository.raw.to_s, "refs/heads/master"])
    expect(results[:details][1][:args]).to eq([project.repository.raw.to_s, "HEAD"])
  end
end
