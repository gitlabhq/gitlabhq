# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SyntheticNote do
  describe '#to_ability_name' do
    subject { described_class.new.to_ability_name }

    it { is_expected.to eq('note') }
  end
end
