# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Serializer::Ci::Variables do
  subject do
    described_class.load(described_class.dump(object))
  end

  let(:object) do
    [{ 'key' => :key, 'value' => 'value', 'public' => true },
     { key: 'wee', value: 1, public: false }]
  end

  it 'converts keys into strings and symbolizes hash' do
    is_expected.to eq(
      [
        { key: 'key', value: 'value', public: true },
        { key: 'wee', value: 1, public: false }
      ])
  end
end
