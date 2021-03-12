# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WordDiff::Segments::Newline do
  subject(:newline) { described_class.new }

  describe '#to_s' do
    subject { newline.to_s }

    it { is_expected.to eq '' }
  end
end
