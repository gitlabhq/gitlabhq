require 'spec_helper'

describe Gitlab::Diff::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff) }

  describe '.process_diff_lines' do
    let(:diff_lines) { Gitlab::Diff::Highlight.process_diff_lines(diff_file) }

    it 'should return Gitlab::Diff::Line elements' do
      expect(diff_lines.first).to be_an_instance_of(Gitlab::Diff::Line)
    end

    it 'should highlight the code' do
      code = %Q{<span id="LC3" class="line">   <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

      expect(diff_lines[2].text).to eq(code)
    end

    it 'should keep the inline diff markup' do
      expect(diff_lines[5].text).to match(Regexp.new(Regexp.escape('<span class="idiff">RuntimeError, </span>')))
    end
  end
end
