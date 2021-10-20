# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::DelegatorOverride::Error do
  let(:error) { described_class.new('foo', 'Target', '/path/to/target', 'Delegator', '/path/to/delegator') }

  describe '#to_s' do
    subject { error.to_s }

    it { is_expected.to eq("Delegator#foo is overriding Target#foo. delegator_location: /path/to/delegator target_location: /path/to/target") }
  end
end
