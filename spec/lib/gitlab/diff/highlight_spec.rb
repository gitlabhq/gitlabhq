require 'spec_helper'

describe Gitlab::Diff::Highlight do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }

  describe '#highlight' do
    context "with a diff file" do
      let(:subject) { described_class.new(diff_file, repository: project.repository).highlight }

      it 'returns Gitlab::Diff::Line elements' do
        expect(subject.first).to be_an_instance_of(Gitlab::Diff::Line)
      end

      it 'does not modify "match" lines' do
        expect(subject[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(subject[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end

      it 'highlights and marks unchanged lines' do
        code = %Q{ <span id="LC7" class="line" lang="ruby">  <span class="k">def</span> <span class="nf">popen</span><span class="p">(</span><span class="n">cmd</span><span class="p">,</span> <span class="n">path</span><span class="o">=</span><span class="kp">nil</span><span class="p">)</span></span>\n}

        expect(subject[2].text).to eq(code)
      end

      it 'highlights and marks removed lines' do
        code = %Q{-<span id="LC9" class="line" lang="ruby">      <span class="k">raise</span> <span class="s2">"System commands must be given as an array of strings"</span></span>\n}

        expect(subject[4].text).to eq(code)
      end

      it 'highlights and marks added lines' do
        code = %Q{+<span id="LC9" class="line" lang="ruby">      <span class="k">raise</span> <span class="no"><span class="idiff left">RuntimeError</span></span><span class="p"><span class="idiff">,</span></span><span class="idiff right"> </span><span class="s2">"System commands must be given as an array of strings"</span></span>\n}

        expect(subject[5].text).to eq(code)
      end
    end

    context "with diff lines" do
      let(:subject) { described_class.new(diff_file.diff_lines, repository: project.repository).highlight }

      it 'returns Gitlab::Diff::Line elements' do
        expect(subject.first).to be_an_instance_of(Gitlab::Diff::Line)
      end

      it 'does not modify "match" lines' do
        expect(subject[0].text).to eq('@@ -6,12 +6,18 @@ module Popen')
        expect(subject[22].text).to eq('@@ -19,6 +25,7 @@ module Popen')
      end

      it 'marks unchanged lines' do
        code = %q{   def popen(cmd, path=nil)}

        expect(subject[2].text).to eq(code)
        expect(subject[2].text).not_to be_html_safe
      end

      it 'marks removed lines' do
        code = %q{-      raise "System commands must be given as an array of strings"}

        expect(subject[4].text).to eq(code)
        expect(subject[4].text).not_to be_html_safe
      end

      it 'marks added lines' do
        code = %q{+      raise <span class="idiff left right">RuntimeError, </span>&quot;System commands must be given as an array of strings&quot;}

        expect(subject[5].text).to eq(code)
        expect(subject[5].text).to be_html_safe
      end

      context 'when the inline diff marker has an invalid range' do
        before do
          allow_any_instance_of(Gitlab::Diff::InlineDiffMarker).to receive(:mark).and_raise(RangeError)
        end

        it 'keeps the original rich line' do
          code = %q{+      raise RuntimeError, "System commands must be given as an array of strings"}

          expect(subject[5].text).to eq(code)
          expect(subject[5].text).not_to be_html_safe
        end

        it 'reports to Sentry if configured' do
          allow(Gitlab::Sentry).to receive(:enabled?).and_return(true)

          expect(Gitlab::Sentry).to receive(:context)
          expect(Raven).to receive(:capture_exception)

          subject
        end
      end
    end
  end
end
