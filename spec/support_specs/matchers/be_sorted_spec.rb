# frozen_string_literal: true

require 'fast_spec_helper'

load File.expand_path('../../../spec/support/matchers/be_sorted.rb', __dir__)

RSpec.describe 'be_sorted' do
  it 'matches empty collections, regardless of arguments' do
    expect([])
      .to be_sorted
      .and be_sorted.asc
      .and be_sorted.desc
      .and be_sorted(:foo)
      .and be_sorted(:bar)

    expect([].to_set).to be_sorted
    expect({}).to be_sorted
  end

  it 'matches in both directions' do
    expect([1, 2, 3]).to be_sorted.asc
    expect([3, 2, 1]).to be_sorted.desc
  end

  it 'can match on a projection' do
    xs = [['a', 10], ['b', 7], ['c', 4]]

    expect(xs).to be_sorted.asc.by(&:first)
    expect(xs).to be_sorted(:first, :asc)
    expect(xs).to be_sorted.desc.by(&:second)
    expect(xs).to be_sorted(:second, :desc)
  end
end
