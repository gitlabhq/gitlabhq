require 'spec_helper'

describe Gitlab::Diff::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, [commit.parent, commit]) }

  describe '#highlight' do
    context "with a diff file" do
      let(:subject) { Gitlab::Diff::Highlight.new(diff_file).highlight }

      it 'should return Gitlab::Diff::Line elements' do
        expect(subject.first).to be_an_instance_of(Gitlab::Diff::Line)
      end

      it 'should not modify "match" lines' do
        expect(subject[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(subject[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end

      it 'highlights and marks unchanged lines' do
        code = %Q{ <span id="LC7" class="line">  <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

        expect(subject[2].text).to eq(code)
      end

      it 'highlights and marks removed lines' do
        code = %Q{-<span id="LC9" class="line">      <span class="k">raise</span> <span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

        expect(subject[4].text).to eq(code)
      end

      it 'highlights and marks added lines' do
        code = %Q{+<span id="LC9" class="line">      <span class="k">raise</span> <span class="no"><span class='idiff left'>RuntimeError</span></span><span class="p"><span class='idiff'>,</span></span><span class='idiff right'> </span><span class="s2">&quot;System commands must be given as an array of strings&quot;</span></span>\n}

        expect(subject[5].text).to eq(code)
      end
    end

    context "with diff lines" do
      let(:subject) { Gitlab::Diff::Highlight.new(diff_file.diff_lines).highlight }

      it 'should return Gitlab::Diff::Line elements' do
        expect(subject.first).to be_an_instance_of(Gitlab::Diff::Line)
      end

      it 'should not modify "match" lines' do
        expect(subject[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(subject[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end

      it 'marks unchanged lines' do
        code = %Q{   def popen(cmd, path=nil)}

        expect(subject[2].text).to eq(code)
        expect(subject[2].text).not_to be_html_safe
      end

      it 'marks removed lines' do
        code = %Q{-      raise "System commands must be given as an array of strings"}

        expect(subject[4].text).to eq(code)
        expect(subject[4].text).not_to be_html_safe
      end

      it 'marks added lines' do
        code = %Q{+      raise <span class='idiff left right'>RuntimeError, </span>&quot;System commands must be given as an array of strings&quot;}

        expect(subject[5].text).to eq(code)
        expect(subject[5].text).to be_html_safe
      end
    end
  end
end
