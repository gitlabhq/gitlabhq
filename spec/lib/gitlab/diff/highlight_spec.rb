require 'spec_helper'

describe Gitlab::Diff::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff) }

  describe '.process_diff_lines' do
    context 'when processing Gitlab::Diff::Line objects' do
      let(:diff_lines) { Gitlab::Diff::Highlight.process_diff_lines(diff_file.new_path, diff_file.diff_lines) }

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

      it 'should not modify "match" lines' do
        expect(diff_lines[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(diff_lines[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end
    end

    context 'when processing raw lines' do
      let(:lines) { ["puts 'Hello'\n", "# A comment"] }
      let(:highlighted_lines) { Gitlab::Diff::Highlight.process_diff_lines('demo.rb', lines) }

      it 'should highlight the code' do
        line_1 = %Q{<span id="LC1" class="line"><span class="nb">puts</span> <span class="s1">&#39;Hello&#39;</span></span>\n}
        line_2 = %Q{<span id="LC2" class="line"><span class="c1"># A comment</span></span>}

        expect(highlighted_lines[0]).to eq(line_1)
        expect(highlighted_lines[1]).to eq(line_2)
      end
    end

  end
end
