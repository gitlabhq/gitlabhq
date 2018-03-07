require 'spec_helper'

describe Gitlab::Diff::InlineDiff do
  describe '.for_lines' do
    let(:diff) do
      <<-EOF.strip_heredoc
         class Test
        -  def initialize(test = true)
        +  def initialize(test = false)
             @test = test
        -    if true
        -      @foo = "bar"
        +    unless false
        +      @foo = "baz"
             end
           end
         end
      EOF
    end

    let(:subject) { described_class.for_lines(diff.lines) }

    it 'finds all inline diffs' do
      expect(subject[0]).to be_nil
      expect(subject[1]).to eq([25..27])
      expect(subject[2]).to eq([25..28])
      expect(subject[3]).to be_nil
      expect(subject[4]).to eq([5..10])
      expect(subject[5]).to eq([17..17])
      expect(subject[6]).to eq([5..15])
      expect(subject[7]).to eq([17..17])
      expect(subject[8]).to be_nil
    end

    it 'can handle unchanged empty lines' do
      expect { described_class.for_lines(['- bar', '+ baz', '']) }.not_to raise_error
    end
  end

  describe "#inline_diffs" do
    let(:old_line) { "XXX def initialize(test = true)" }
    let(:new_line) { "YYY def initialize(test = false)" }
    let(:subject) { described_class.new(old_line, new_line, offset: 3).inline_diffs }

    it "finds the inline diff" do
      old_diffs, new_diffs = subject

      expect(old_diffs).to eq([26..28])
      expect(new_diffs).to eq([26..29])
    end
  end
end
