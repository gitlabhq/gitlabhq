# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Diff::PairSelector do
  subject(:selector) { described_class.new(lines) }

  describe '#to_a' do
    subject { selector.to_a }

    let(:lines) { diff.lines }

    let(:diff) do
      <<~DIFF
         class Test                       # 0
        -  def initialize(test = true)    # 1
        +  def initialize(test = false)   # 2
             @test = test                 # 3
        -    if true                      # 4
        -      @foo = "bar"               # 5
        +    unless false                 # 6
        +      @foo = "baz"               # 7
             end
           end
         end
      DIFF
    end

    it 'finds all pairs' do
      is_expected.to match_array([[1, 2], [4, 6], [5, 7]])
    end

    context 'when there are empty lines' do
      let(:lines) { ['- bar', '+ baz', ''] }

      it { expect { subject }.not_to raise_error }
    end

    context 'when there are only removals' do
      let(:diff) do
        <<~DIFF
          - class Test
          -  def initialize(test = true)
          -  end
          - end
        DIFF
      end

      it 'returns empty collection' do
        is_expected.to eq([])
      end
    end

    context 'when there are only additions' do
      let(:diff) do
        <<~DIFF
          + class Test
          +  def initialize(test = true)
          +  end
          + end
        DIFF
      end

      it 'returns empty collection' do
        is_expected.to eq([])
      end
    end

    context 'when there are no changes' do
      let(:diff) do
        <<~DIFF
           class Test
             def initialize(test = true)
             end
           end
        DIFF
      end

      it 'returns empty collection' do
        is_expected.to eq([])
      end
    end
  end
end
