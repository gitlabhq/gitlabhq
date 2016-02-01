require 'spec_helper'

describe Gitlab::Diff::InlineDiff, lib: true do
  describe '.for_lines' do
    let(:diff) do
      <<eos
 class Test
-  def initialize(test = true)
+  def initialize(test = false)
     @test = test
   end
 end
eos
    end

    let(:subject) { described_class.for_lines(diff.lines) }

    it 'finds all inline diffs' do
      expect(subject[0]).to be_nil
      expect(subject[1]).to eq([25..27])
      expect(subject[2]).to eq([25..28])
      expect(subject[3]).to be_nil
      expect(subject[4]).to be_nil
      expect(subject[5]).to be_nil
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
