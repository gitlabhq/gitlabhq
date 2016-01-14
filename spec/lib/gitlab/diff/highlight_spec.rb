require 'spec_helper'

describe Gitlab::Diff::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, [commit.parent.id, commit.id], project.repository) }

  describe '.process_diff_lines' do
    context 'when processing Gitlab::Diff::Line objects' do
      let(:diff_lines) { Gitlab::Diff::Highlight.process_diff_lines(diff_file) }

      it 'should return Gitlab::Diff::Line elements' do
        expect(diff_lines.first).to be_an_instance_of(Gitlab::Diff::Line)
      end

      it 'should highlight the code' do
        code = %Q{ <span id="LC7" class="line">  <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

        expect(diff_lines[2].text).to eq(code)
      end

      it 'should not generate the inline diff markup' do
        expect(diff_lines[5].text).not_to match(Regexp.new(Regexp.escape('<span class="idiff">')))
      end

      it 'should not modify "match" lines' do
        expect(diff_lines[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(diff_lines[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end

      it 'should highlight unchanged lines' do
        code = %Q{ <span id="LC7" class="line">  <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

        expect(diff_lines[2].text).to eq(code)
      end

      it 'should highlight added lines' do
        code = %Q{+<span id="LC9" class="line">      <span class="k">raise</span> <span class="no">RuntimeError</span><span class="p">,</span> <span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

        expect(diff_lines[5].text).to eq(code)
      end

      it 'should highlight removed lines' do
        code = %Q{-<span id="LC9" class="line">      <span class="k">raise</span> <span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

        expect(diff_lines[4].text).to eq(code)
      end
    end
  end

  describe '.highlight_lines' do
    let(:lines) do
      Gitlab::Diff::Highlight.highlight_lines(project.repository, commit.id, 'files/ruby/popen.rb')
    end

    it 'should properly highlight all the lines' do
      expect(lines[4]).to eq(%Q{<span id="LC5" class="line">  <span class="kp">extend</span> <span class="nb">self</span></span>\n})
      expect(lines[21]).to eq(%Q{<span id="LC22" class="line">    <span class="k">unless</span> <span class="no">File</span><span class="p">.</span><span class="nf">directory?</span><span class="p">(</span><span class="n">path</span><span class="p">)</span></span>\n})
      expect(lines[26]).to eq(%Q{<span id="LC27" class="line">    <span class="vi">@cmd_status</span> <span class="o">=</span> <span class="mi">0</span></span>\n})
    end
  end

end
