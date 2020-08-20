# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Normalizer::Factory do
  describe '#create' do
    context 'when no strategy applies' do
      subject(:subject) { described_class.new(nil, nil).create } # rubocop:disable Rails/SaveBang

      it { is_expected.to be_empty }
    end
  end
end
