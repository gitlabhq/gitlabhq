require 'spec_helper'

describe Gitlab::Diff::InlineDiff, lib: true do
  describe '#inline_diffs' do
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

    let(:subject) { Gitlab::Diff::InlineDiff.new(diff.lines).inline_diffs }

    it 'finds all inline diffs' do
      expect(subject[0]).to be_nil
      expect(subject[1]).to eq([25..27])
      expect(subject[2]).to eq([25..28])
      expect(subject[3]).to be_nil
      expect(subject[4]).to be_nil
      expect(subject[5]).to be_nil
    end
  end
end
