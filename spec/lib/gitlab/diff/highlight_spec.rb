require 'spec_helper'

describe Gitlab::Diff::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, [commit.parent, commit]) }

  describe '#highlight' do
    let(:diff_lines) { Gitlab::Diff::Highlight.new(diff_file).highlight }

    it 'should return Gitlab::Diff::Line elements' do
      expect(diff_lines.first).to be_an_instance_of(Gitlab::Diff::Line)
    end

    it 'should not modify "match" lines' do
      expect(diff_lines[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
      expect(diff_lines[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
    end

    it 'should highlight unchanged lines' do
      code = %Q{ <span id="LC7" class="line">  <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

      expect(diff_lines[2].text).to eq(code)
    end

    it 'should highlight removed lines' do
      code = %Q{-<span id="LC9" class="line">      <span class="k">raise</span> <span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

      expect(diff_lines[4].text).to eq(code)
    end

    it 'should highlight added lines' do
      code = %Q{+<span id="LC9" class="line">      <span class="k">raise</span> <span class="no"><span class='idiff'>RuntimeError</span></span><span class="p"><span class='idiff'>,</span></span> <span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

      expect(diff_lines[5].text).to eq(code)
    end
  end
end
