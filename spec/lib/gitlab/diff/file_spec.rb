require 'spec_helper'

describe Gitlab::Diff::File do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { described_class.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }

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

  describe '#old_blob' do
    it 'returns blob of commit of base commit' do
      old_data = diff_file.old_blob.data

      expect(old_data).to include('raise "System commands must be given as an array of strings"')
    end
  end

  describe '#new_blob' do
    it 'returns blob of new commit' do
      data = diff_file.new_blob.data

      expect(data).to include('raise RuntimeError, "System commands must be given as an array of strings"')
    end
  end

  describe '#diffable?' do
    let(:commit) { project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }
    let(:diffs) { commit.diffs }

    before do
      info_dir_path = File.join(project.repository.path_to_repo, 'info')

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

  describe '#simple_viewer' do
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
          allow(diff_file).to receive(:raw_binary?).and_return(true)
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
          allow(diff_file).to receive(:raw_binary?).and_return(true)
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
          allow(diff_file).to receive(:raw_binary?).and_return(true)
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
        allow(diff_file).to receive(:raw_text?).and_return(false)
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
end
