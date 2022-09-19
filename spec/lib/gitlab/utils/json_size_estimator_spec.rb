# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::JsonSizeEstimator do
  RSpec::Matchers.define :match_json_bytesize_of do |expected|
    match do |actual|
      actual == expected.to_json.bytesize
    end
  end

  def estimate(object)
    described_class.estimate(object)
  end

  [
    [],
    [[[[]]]],
    [1, "str", 3.14, ["str", { a: -1 }]],
    {},
    { a: {} },
    { a: { b: { c: [1, 2, 3], e: Time.now, f: nil } } },
    { 100 => 500 },
    { '狸' => '狸' },
    nil
  ].each do |example|
    it { expect(estimate(example)).to match_json_bytesize_of(example) }
  end

  it 'calls #to_s on unknown object' do
    klass = Class.new do
      def to_s
        'hello'
      end
    end

    expect(estimate(klass.new)).to match_json_bytesize_of(klass.new.to_s) # "hello"
  end
end
