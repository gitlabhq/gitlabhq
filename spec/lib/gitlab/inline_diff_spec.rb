require 'spec_helper'

describe Gitlab::InlineDiff do
  describe '#processing' do
    let(:diff) do
      <<eos
--- a/test.rb
+++ b/test.rb
@@ -1,6 +1,6 @@
 class Test
   def cleanup_string(input)
     return nil if input.nil?
-    input.sub(/[\\r\\n].+/,'').sub(/\\\\[rn].+/, '').strip
+    input.to_s.sub(/[\\r\\n].+/,'').sub(/\\\\[rn].+/, '').strip
   end
 end
eos
    end

    let(:expected) do
      ["--- a/test.rb\n",
       "+++ b/test.rb\n",
       "@@ -1,6 +1,6 @@\n",
       " class Test\n",
       "   def cleanup_string(input)\n",
       "     return nil if input.nil?\n",
       "-    input.#!idiff-start!##!idiff-finish!#sub(/[\\r\\n].+/,'').sub(/\\\\[rn].+/, '').strip\n",
       "+    input.#!idiff-start!#to_s.#!idiff-finish!#sub(/[\\r\\n].+/,'').sub(/\\\\[rn].+/, '').strip\n",
       "   end\n",
       " end\n"]
    end

    let(:subject) { Gitlab::InlineDiff.processing(diff.lines) }

    it 'should retain backslashes' do
      expect(subject).to eq(expected)
    end
  end
end
