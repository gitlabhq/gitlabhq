# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::File do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { described_class.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }

  def create_file(file_name, content)
    Files::CreateService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name,
      file_content: content
    ).execute

    project.commit(branch_name).diffs.diff_files.first
  end

  def update_file(file_name, content)
    Files::UpdateService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name,
      file_content: content
    ).execute

    project.commit(branch_name).diffs.diff_files.first
  end

  def delete_file(file_name)
    Files::DeleteService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name
    ).execute

    project.commit(branch_name).diffs.diff_files.first
  end

  describe '#diff_lines' do
    let(:diff_lines) { diff_file.diff_lines }

    it { expect(diff_lines.size).to eq(30) }
    it { expect(diff_lines.first).to be_kind_of(Gitlab::Diff::Line) }
  end

  describe '#highlighted_diff_lines' do
    it 'highlights the diff and memoises the result' do
      expect(Gitlab::Diff::Highlight).to receive(:new)
                                           .with(diff_file, repository: project.repository)
                                           .once
                                           .and_call_original

      diff_file.highlighted_diff_lines
    end
  end

  describe '#diff_lines_for_serializer' do
    it 'includes bottom match line if not in the end' do
      expect(diff_file.diff_lines_for_serializer.last.type).to eq('match')
    end

    context 'when called multiple times' do
      it 'only adds bottom match line once' do
        expect(diff_file.diff_lines_for_serializer.size).to eq(31)
        expect(diff_file.diff_lines_for_serializer.size).to eq(31)
      end
    end

    context 'when deleted' do
      let(:commit) { project.commit('d59c60028b053793cecfb4022de34602e1a9218e') }
      let(:diff_file) { commit.diffs.diff_file_with_old_path('files/js/commit.js.coffee') }

      it 'does not include bottom match line' do
        expect(diff_file.diff_lines_for_serializer.last.type).not_to eq('match')
      end
    end
  end

  describe '#unfold_diff_lines' do
    let(:unfolded_lines) { double('expanded-lines') }
    let(:unfolder) { instance_double(Gitlab::Diff::LinesUnfolder) }
    let(:position) { instance_double(Gitlab::Diff::Position, old_line: 10) }

    before do
      allow(Gitlab::Diff::LinesUnfolder).to receive(:new) { unfolder }
    end

    context 'when unfold required' do
      before do
        allow(unfolder).to receive(:unfold_required?) { true }
        allow(unfolder).to receive(:unfolded_diff_lines) { unfolded_lines }
      end

      it 'changes @unfolded to true' do
        diff_file.unfold_diff_lines(position)

        expect(diff_file).to be_unfolded
      end

      it 'updates @diff_lines' do
        diff_file.unfold_diff_lines(position)

        expect(diff_file.diff_lines).to eq(unfolded_lines)
      end
    end

    context 'when unfold not required' do
      before do
        allow(unfolder).to receive(:unfold_required?) { false }
      end

      it 'keeps @unfolded false' do
        diff_file.unfold_diff_lines(position)

        expect(diff_file).not_to be_unfolded
      end

      it 'does not update @diff_lines' do
        expect { diff_file.unfold_diff_lines(position) }
          .not_to change(diff_file, :diff_lines)
      end
    end
  end

  describe '#mode_changed?' do
    it { expect(diff_file.mode_changed?).to be_falsey }
  end

  describe '#too_large?' do
    it 'returns true for a file that is too large' do
      expect(diff).to receive(:too_large?).and_return(true)

      expect(diff_file.too_large?).to eq(true)
    end

    it 'returns false for a file that is small enough' do
      expect(diff).to receive(:too_large?).and_return(false)

      expect(diff_file.too_large?).to eq(false)
    end
  end

  describe '#collapsed?' do
    it 'returns true for a file that is quite big' do
      expect(diff).to receive(:collapsed?).and_return(true)

      expect(diff_file.collapsed?).to eq(true)
    end

    it 'returns false for a file that is small enough' do
      expect(diff).to receive(:collapsed?).and_return(false)

      expect(diff_file.collapsed?).to eq(false)
    end
  end

  describe '#old_blob and #new_blob' do
    it 'returns blob of base commit and the new commit' do
      items = [
        [diff_file.new_content_sha, diff_file.new_path], [diff_file.old_content_sha, diff_file.old_path]
      ]

      expect(project.repository).to receive(:blobs_at).with(items, blob_size_limit: 10.megabytes).and_call_original

      old_data = diff_file.old_blob.data
      data = diff_file.new_blob.data

      expect(old_data).to include('raise "System commands must be given as an array of strings"')
      expect(data).to include('raise RuntimeError, "System commands must be given as an array of strings"')
    end
  end

  describe '#diffable?' do
    context 'when attributes exist' do
      let(:commit) { project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }
      let(:diffs) { commit.diffs }

      before do
        info_dir_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          File.join(project.repository.path_to_repo, 'info')
        end

        FileUtils.mkdir(info_dir_path) unless File.exist?(info_dir_path)
        File.write(File.join(info_dir_path, 'attributes'), "*.md -diff\n")
      end

      it "returns true for files that do not have attributes" do
        diff_file = diffs.diff_file_with_new_path('LICENSE')
        expect(diff_file.diffable?).to be_truthy
      end

      it "returns false for files that have been marked as not being diffable in attributes" do
        diff_file = diffs.diff_file_with_new_path('README.md')
        expect(diff_file.diffable?).to be_falsey
      end
    end

    context 'when the text has binary notice' do
      let(:commit) { project.commit('f05a98786e4274708e1fa118c7ad3a29d1d1b9a3') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('VERSION') }

      it "returns false" do
        expect(diff_file.diffable?).to be_falsey
      end
    end

    context 'when the content is binary' do
      let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      it "returns true" do
        expect(diff_file.diffable?).to be_truthy
      end
    end
  end

  describe '#content_changed?' do
    context 'when created' do
      let(:commit) { project.commit('33f3729a45c02fc67d00adb1b8bca394b0e761d9') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      it 'returns false' do
        expect(diff_file.content_changed?).to be_falsey
      end
    end

    context 'when deleted' do
      let(:commit) { project.commit('d59c60028b053793cecfb4022de34602e1a9218e') }
      let(:diff_file) { commit.diffs.diff_file_with_old_path('files/js/commit.js.coffee') }

      it 'returns false' do
        expect(diff_file.content_changed?).to be_falsey
      end
    end

    context 'when renamed' do
      let(:commit) { project.commit('94bb47ca1297b7b3731ff2a36923640991e9236f') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('CHANGELOG.md') }

      it 'returns false' do
        expect(diff_file.content_changed?).to be_falsey
      end
    end

    context 'when content changed' do
      context 'when binary' do
        let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
        let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

        context 'when the blobs are different' do
          it 'returns true' do
            expect(diff_file.content_changed?).to be_truthy
          end
        end

        context 'when there are no diff refs' do
          before do
            allow(diff_file).to receive(:diff_refs).and_return(nil)
          end

          it 'returns false' do
            expect(diff_file.content_changed?).to be_falsey
          end
        end
      end

      context 'when not binary' do
        let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
        let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

        context 'when the blobs are different' do
          it 'returns true' do
            expect(diff_file.content_changed?).to be_truthy
          end
        end

        context 'when there are no diff refs' do
          before do
            allow(diff_file).to receive(:diff_refs).and_return(nil)
          end

          it 'returns true' do
            expect(diff_file.content_changed?).to be_truthy
          end
        end
      end
    end
  end

  describe '#file_hash' do
    it 'returns a hash of file_path' do
      expect(diff_file.file_hash).to eq(Digest::SHA1.hexdigest(diff_file.file_path))
    end
  end

  describe '#file_identifier_hash' do
    it 'returns a hash of file_identifier' do
      expect(diff_file.file_identifier_hash).to eq(Digest::SHA1.hexdigest(diff_file.file_identifier))
    end
  end

  context 'diff file stats' do
    let(:diff_file) do
      described_class.new(diff,
                          diff_refs: commit.diff_refs,
                          repository: project.repository,
                          stats: stats)
    end

    let(:raw_diff) do
      <<~EOS
        --- a/files/ruby/popen.rb
        +++ b/files/ruby/popen.rb
        @@ -6,12 +6,18 @@ module Popen

           def popen(cmd, path=nil)
             unless cmd.is_a?(Array)
        -      raise "System commands must be given as an array of strings"
        +      raise RuntimeError, "System commands must be given as an array of strings"
        +      # foobar
             end
      EOS
    end

    describe '#added_lines' do
      context 'when stats argument given' do
        let(:stats) { double(Gitaly::DiffStats, additions: 10, deletions: 15) }

        it 'returns added lines from stats' do
          expect(diff_file.added_lines).to eq(stats.additions)
        end
      end

      context 'when stats argument not given' do
        let(:stats) { nil }

        it 'returns added lines by parsing raw diff' do
          allow(diff_file).to receive(:raw_diff) { raw_diff }

          expect(diff_file.added_lines).to eq(2)
        end
      end
    end

    describe '#removed_lines' do
      context 'when stats argument given' do
        let(:stats) { double(Gitaly::DiffStats, additions: 10, deletions: 15) }

        it 'returns removed lines from stats' do
          expect(diff_file.removed_lines).to eq(stats.deletions)
        end
      end

      context 'when stats argument not given' do
        let(:stats) { nil }

        it 'returns removed lines by parsing raw diff' do
          allow(diff_file).to receive(:raw_diff) { raw_diff }

          expect(diff_file.removed_lines).to eq(1)
        end
      end
    end
  end

  describe '#simple_viewer' do
    context 'when the file is collapsed' do
      before do
        allow(diff_file).to receive(:collapsed?).and_return(true)
      end

      it 'returns a Collapsed viewer' do
        expect(diff_file.simple_viewer).to be_a(DiffViewer::Collapsed)
      end
    end

    context 'when the file is not diffable' do
      before do
        allow(diff_file).to receive(:diffable?).and_return(false)
      end

      it 'returns a Not Diffable viewer' do
        expect(diff_file.simple_viewer).to be_a(DiffViewer::NotDiffable)
      end
    end

    context 'when the content changed' do
      context 'when the file represented by the diff file is binary' do
        before do
          allow(diff_file).to receive(:binary?).and_return(true)
        end

        it 'returns a No Preview viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::NoPreview)
        end
      end

      context 'when the diff file old and new blob types are different' do
        before do
          allow(diff_file).to receive(:different_type?).and_return(true)
        end

        it 'returns a No Preview viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::NoPreview)
        end
      end

      context 'when the file represented by the diff file is text-based' do
        it 'returns a text viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Text)
        end
      end
    end

    context 'when created' do
      let(:commit) { project.commit('913c66a37b4a45b9769037c55c2d238bd0942d2e') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

      before do
        allow(diff_file).to receive(:content_changed?).and_return(nil)
      end

      context 'when the file represented by the diff file is binary' do
        before do
          allow(diff_file).to receive(:binary?).and_return(true)
        end

        it 'returns an Added viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Added)
        end
      end

      context 'when the diff file old and new blob types are different' do
        before do
          allow(diff_file).to receive(:different_type?).and_return(true)
        end

        it 'returns an Added viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Added)
        end
      end

      context 'when the file represented by the diff file is text-based' do
        it 'returns a text viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Text)
        end
      end
    end

    context 'when deleted' do
      let(:commit) { project.commit('d59c60028b053793cecfb4022de34602e1a9218e') }
      let(:diff_file) { commit.diffs.diff_file_with_old_path('files/js/commit.js.coffee') }

      before do
        allow(diff_file).to receive(:content_changed?).and_return(nil)
      end

      context 'when the file represented by the diff file is binary' do
        before do
          allow(diff_file).to receive(:binary?).and_return(true)
        end

        it 'returns a Deleted viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Deleted)
        end
      end

      context 'when the diff file old and new blob types are different' do
        before do
          allow(diff_file).to receive(:different_type?).and_return(true)
        end

        it 'returns a Deleted viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Deleted)
        end
      end

      context 'when the file represented by the diff file is text-based' do
        it 'returns a text viewer' do
          expect(diff_file.simple_viewer).to be_a(DiffViewer::Text)
        end
      end
    end

    context 'when renamed' do
      let(:commit) { project.commit('6907208d755b60ebeacb2e9dfea74c92c3449a1f') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/js/commit.coffee') }

      before do
        allow(diff_file).to receive(:content_changed?).and_return(nil)
      end

      it 'returns a Renamed viewer' do
        expect(diff_file.simple_viewer).to be_a(DiffViewer::Renamed)
      end
    end

    context 'when mode changed' do
      before do
        allow(diff_file).to receive(:content_changed?).and_return(nil)
        allow(diff_file).to receive(:mode_changed?).and_return(true)
      end

      it 'returns a Mode Changed viewer' do
        expect(diff_file.simple_viewer).to be_a(DiffViewer::ModeChanged)
      end
    end

    context 'when no other conditions apply' do
      before do
        allow(diff_file).to receive(:content_changed?).and_return(false)
        allow(diff_file).to receive(:new_file?).and_return(false)
        allow(diff_file).to receive(:deleted_file?).and_return(false)
        allow(diff_file).to receive(:renamed_file?).and_return(false)
        allow(diff_file).to receive(:mode_changed?).and_return(false)
        allow(diff_file).to receive(:text?).and_return(false)
      end

      it 'returns a No Preview viewer' do
        expect(diff_file.simple_viewer).to be_a(DiffViewer::NoPreview)
      end
    end
  end

  describe '#rich_viewer' do
    let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
    let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

    context 'when the diff file has a matching viewer' do
      context 'when the diff file content did not change' do
        before do
          allow(diff_file).to receive(:content_changed?).and_return(false)
        end

        it 'returns nil' do
          expect(diff_file.rich_viewer).to be_nil
        end
      end

      context 'when the diff file is not diffable' do
        before do
          allow(diff_file).to receive(:diffable?).and_return(false)
        end

        it 'returns nil' do
          expect(diff_file.rich_viewer).to be_nil
        end
      end

      context 'when the diff file old and new blob types are different' do
        before do
          allow(diff_file).to receive(:different_type?).and_return(true)
        end

        it 'returns nil' do
          expect(diff_file.rich_viewer).to be_nil
        end
      end

      context 'when the diff file has an external storage error' do
        before do
          allow(diff_file).to receive(:external_storage_error?).and_return(true)
        end

        it 'returns nil' do
          expect(diff_file.rich_viewer).to be_nil
        end
      end

      context 'when everything is right' do
        it 'returns the viewer' do
          expect(diff_file.rich_viewer).to be_a(DiffViewer::Image)
        end
      end
    end

    context 'when the diff file does not have a matching viewer' do
      let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

      it 'returns nil' do
        expect(diff_file.rich_viewer).to be_nil
      end
    end
  end

  describe '#alternate_viewer' do
    subject { diff_file.alternate_viewer }

    where(:viewer_class) do
      [
        DiffViewer::Image,
        DiffViewer::Collapsed,
        DiffViewer::NotDiffable,
        DiffViewer::Text,
        DiffViewer::NoPreview,
        DiffViewer::Added,
        DiffViewer::Deleted,
        DiffViewer::ModeChanged,
        DiffViewer::ModeChanged,
        DiffViewer::NoPreview
      ]
    end

    with_them do
      let(:viewer) { viewer_class.new(diff_file) }

      before do
        allow(diff_file).to receive(:viewer).and_return(viewer)
      end

      it { is_expected.to be_nil }
    end

    context 'when viewer is DiffViewer::Renamed' do
      let(:viewer) { DiffViewer::Renamed.new(diff_file) }

      before do
        allow(diff_file).to receive(:viewer).and_return(viewer)
      end

      context 'when it can be rendered as text' do
        it { is_expected.to be_a(DiffViewer::Text) }
      end

      context 'when it can be rendered as image' do
        let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
        let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

        it { is_expected.to be_a(DiffViewer::Image) }
      end

      context 'when it is something else' do
        let(:commit) { project.commit('ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
        let(:diff_file) { commit.diffs.diff_file_with_new_path('Gemfile.zip') }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#rendered_as_text?' do
    context 'when the simple viewer is text-based' do
      let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

      context 'when ignoring errors' do
        context 'when the viewer has render errors' do
          before do
            diff_file.diff.too_large!
          end

          it 'returns true' do
            expect(diff_file.rendered_as_text?).to be_truthy
          end
        end

        context "when the viewer doesn't have render errors" do
          it 'returns true' do
            expect(diff_file.rendered_as_text?).to be_truthy
          end
        end
      end

      context 'when not ignoring errors' do
        context 'when the viewer has render errors' do
          before do
            diff_file.diff.too_large!
          end

          it 'returns false' do
            expect(diff_file.rendered_as_text?(ignore_errors: false)).to be_falsey
          end
        end

        context "when the viewer doesn't have render errors" do
          it 'returns true' do
            expect(diff_file.rendered_as_text?(ignore_errors: false)).to be_truthy
          end
        end
      end
    end

    context 'when the simple viewer is binary' do
      let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      it 'returns false' do
        expect(diff_file.rendered_as_text?).to be_falsey
      end
    end
  end

  context 'when neither blob exists' do
    let(:blank_diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: Gitlab::Git::BLANK_SHA, head_sha: Gitlab::Git::BLANK_SHA) }
    let(:diff_file) { described_class.new(diff, diff_refs: blank_diff_refs, repository: project.repository) }

    describe '#blob' do
      it 'returns a concrete nil so it can be used in boolean expressions' do
        actual = diff_file.blob && true

        expect(actual).to be_nil
      end
    end

    describe '#binary?' do
      it 'returns false' do
        expect(diff_file).not_to be_binary
      end
    end

    describe '#size' do
      it 'returns zero' do
        expect(diff_file.size).to be_zero
      end
    end

    describe '#empty?' do
      it 'returns true' do
        expect(diff_file.empty?).to be_truthy
      end
    end

    describe '#different_type?' do
      it 'returns false' do
        expect(diff_file).not_to be_different_type
      end
    end

    describe '#content_changed?' do
      it 'returns false' do
        expect(diff_file).not_to be_content_changed
      end
    end
  end

  context 'when the the encoding of the file is unsupported' do
    let(:commit) { project.commit('f05a98786e4274708e1fa118c7ad3a29d1d1b9a3') }
    let(:diff_file) { commit.diffs.diff_file_with_new_path('VERSION') }

    it 'returns a Not Diffable viewer' do
      expect(diff_file.simple_viewer).to be_a(DiffViewer::NotDiffable)
    end

    it { expect(diff_file.highlighted_diff_lines).to eq([]) }
    it { expect(diff_file.parallel_diff_lines).to eq([]) }
  end

  describe '#diff_hunk' do
    context 'when first line is a match' do
      let(:raw_diff) do
        <<~EOS
          --- a/files/ruby/popen.rb
          +++ b/files/ruby/popen.rb
          @@ -6,12 +6,18 @@ module Popen

             def popen(cmd, path=nil)
               unless cmd.is_a?(Array)
          -      raise "System commands must be given as an array of strings"
          +      raise RuntimeError, "System commands must be given as an array of strings"
               end
        EOS
      end

      it 'returns raw diff up to given line index' do
        allow(diff_file).to receive(:raw_diff) { raw_diff }
        diff_line = instance_double(Gitlab::Diff::Line, index: 4)

        diff_hunk = <<~EOS
          @@ -6,12 +6,18 @@ module Popen

             def popen(cmd, path=nil)
               unless cmd.is_a?(Array)
          -      raise "System commands must be given as an array of strings"
          +      raise RuntimeError, "System commands must be given as an array of strings"
        EOS

        expect(diff_file.diff_hunk(diff_line)).to eq(diff_hunk.strip)
      end
    end

    context 'when first line is not a match' do
      let(:raw_diff) do
        <<~EOS
          @@ -1,4 +1,4 @@
          -Copyright (c) 2011-2017 GitLab B.V.
          +Copyright (c) 2011-2019 GitLab B.V.

          With regard to the GitLab Software:

          @@ -9,17 +9,21 @@ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
          copies of the Software, and to permit persons to whom the Software is
          furnished to do so, subject to the following conditions:
        EOS
      end

      it 'returns raw diff up to given line index' do
        allow(diff_file).to receive(:raw_diff) { raw_diff }
        diff_line = instance_double(Gitlab::Diff::Line, index: 5)

        diff_hunk = <<~EOS
          -Copyright (c) 2011-2017 GitLab B.V.
          +Copyright (c) 2011-2019 GitLab B.V.

          With regard to the GitLab Software:

          @@ -9,17 +9,21 @@ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
          copies of the Software, and to permit persons to whom the Software is
        EOS

        expect(diff_file.diff_hunk(diff_line)).to eq(diff_hunk.strip)
      end
    end
  end

  describe '#empty?' do
    let(:project) do
      create(:project, :custom_repo, files: {})
    end

    let(:branch_name) { 'master' }

    context 'when empty file is created' do
      it 'returns true' do
        diff_file = create_file('empty.md', '')

        expect(diff_file.empty?).to be_truthy
      end
    end

    context 'when empty file is deleted' do
      it 'returns true' do
        create_file('empty.md', '')
        diff_file = delete_file('empty.md')

        expect(diff_file.empty?).to be_truthy
      end
    end

    context 'when file with content is truncated' do
      it 'returns false' do
        create_file('with-content.md', 'file content')
        diff_file = update_file('with-content.md', '')

        expect(diff_file.empty?).to be_falsey
      end
    end

    context 'when empty file has content added' do
      it 'returns false' do
        create_file('empty.md', '')
        diff_file = update_file('empty.md', 'new content')

        expect(diff_file.empty?).to be_falsey
      end
    end
  end

  describe '#fully_expanded?' do
    let(:project) do
      create(:project, :custom_repo, files: {})
    end

    let(:branch_name) { 'master' }

    context 'when empty file is created' do
      it 'returns true' do
        diff_file = create_file('empty.md', '')

        expect(diff_file.fully_expanded?).to be_truthy
      end
    end

    context 'when empty file is deleted' do
      it 'returns true' do
        create_file('empty.md', '')
        diff_file = delete_file('empty.md')

        expect(diff_file.fully_expanded?).to be_truthy
      end
    end

    context 'when short file with last line removed' do
      it 'returns true' do
        create_file('with-content.md', (1..3).to_a.join("\n"))
        diff_file = update_file('with-content.md', (1..2).to_a.join("\n"))

        expect(diff_file.fully_expanded?).to be_truthy
      end
    end

    context 'when a single line is added to empty file' do
      it 'returns true' do
        create_file('empty.md', '')
        diff_file = update_file('empty.md', 'new content')

        expect(diff_file.fully_expanded?).to be_truthy
      end
    end

    context 'when single line file is changed' do
      it 'returns true' do
        create_file('file.md', 'foo')
        diff_file = update_file('file.md', 'bar')

        expect(diff_file.fully_expanded?).to be_truthy
      end
    end

    context 'when long file is changed' do
      before do
        create_file('file.md', (1..999).to_a.join("\n"))
      end

      context 'when first line is removed' do
        it 'returns true' do
          diff_file = update_file('file.md', (2..999).to_a.join("\n"))

          expect(diff_file.fully_expanded?).to be_falsey
        end
      end

      context 'when last line is removed' do
        it 'returns true' do
          diff_file = update_file('file.md', (1..998).to_a.join("\n"))

          expect(diff_file.fully_expanded?).to be_falsey
        end
      end

      context 'when first and last lines are removed' do
        it 'returns false' do
          diff_file = update_file('file.md', (2..998).to_a.join("\n"))

          expect(diff_file.fully_expanded?).to be_falsey
        end
      end

      context 'when first and last lines are changed' do
        it 'returns false' do
          content = (2..998).to_a
          content.prepend('a')
          content.append('z')
          content = content.join("\n")

          diff_file = update_file('file.md', content)

          expect(diff_file.fully_expanded?).to be_falsey
        end
      end

      context 'when every line are changed' do
        it 'returns true' do
          diff_file = update_file('file.md', "hi\n" * 999)

          expect(diff_file.fully_expanded?).to be_truthy
        end
      end

      context 'when all contents are cleared' do
        it 'returns true' do
          diff_file = update_file('file.md', "")

          expect(diff_file.fully_expanded?).to be_truthy
        end
      end

      context 'when file is binary' do
        it 'returns true' do
          diff_file = update_file('file.md', (1..998).to_a.join("\n"))
          allow(diff_file).to receive(:binary?).and_return(true)

          expect(diff_file.fully_expanded?).to be_truthy
        end
      end
    end
  end
end
