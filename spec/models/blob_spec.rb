# frozen_string_literal: true

require 'spec_helper'

describe Blob do
  include FakeBlobHelpers

  let(:project) { build(:project, lfs_enabled: true) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet) { build(:project_snippet, project: project) }

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '.lazy' do
    let(:commit_id) { 'e63f41fe459e62e1228fcef60d7189127aeba95a' }
    let(:blob_size_limit) { 10 * 1024 * 1024 }

    shared_examples '.lazy checks' do
      it 'does not fetch blobs when none are accessed' do
        expect(container.repository).not_to receive(:blobs_at)

        described_class.lazy(container, commit_id, 'CHANGELOG')
      end

      it 'fetches all blobs for the same repository when one is accessed' do
        expect(container.repository).to receive(:blobs_at)
          .with([[commit_id, 'CHANGELOG'], [commit_id, 'CONTRIBUTING.md']], blob_size_limit: blob_size_limit)
          .once.and_call_original
        expect(other_container.repository).not_to receive(:blobs_at)

        changelog = described_class.lazy(container, commit_id, 'CHANGELOG')
        contributing = described_class.lazy(same_container, commit_id, 'CONTRIBUTING.md')

        described_class.lazy(other_container, commit_id, 'CHANGELOG')

        # Access property so the values are loaded
        changelog.id
        contributing.id
      end

      it 'does not include blobs from previous requests in later requests' do
        changelog = described_class.lazy(container, commit_id, 'CHANGELOG')
        contributing = described_class.lazy(same_container, commit_id, 'CONTRIBUTING.md')

        # Access property so the values are loaded
        changelog.id
        contributing.id

        readme = described_class.lazy(container, commit_id, 'README.md')

        expect(container.repository).to receive(:blobs_at)
          .with([[commit_id, 'README.md']], blob_size_limit: blob_size_limit).once.and_call_original

        readme.id
      end
    end

    context 'with project' do
      let(:container) { create(:project, :repository) }
      let(:same_container) { Project.find(container.id) }
      let(:other_container) { create(:project, :repository) }

      it_behaves_like '.lazy checks'
    end

    context 'with personal snippet' do
      let(:container) { create(:personal_snippet, :repository) }
      let(:same_container) { PersonalSnippet.find(container.id) }
      let(:other_container) { create(:personal_snippet, :repository) }

      it_behaves_like '.lazy checks'
    end

    context 'with project snippet' do
      let(:container) { create(:project_snippet, :repository) }
      let(:same_container) { ProjectSnippet.find(container.id) }
      let(:other_container) { create(:project_snippet, :repository) }

      it_behaves_like '.lazy checks'
    end
  end

  describe '#data' do
    shared_examples '#data checks' do
      context 'using a binary blob' do
        it 'returns the data as-is' do
          data = "\n\xFF\xB9\xC3"
          blob = fake_blob(binary: true, data: data, container: container)

          expect(blob.data).to eq(data)
        end
      end

      context 'using a text blob' do
        it 'converts the data to UTF-8' do
          blob = fake_blob(binary: false, data: "\n\xFF\xB9\xC3", container: container)

          expect(blob.data).to eq("\n���")
        end
      end
    end

    context 'with project' do
      let(:container) { project }

      it_behaves_like '#data checks'
    end

    context 'with personal snippet' do
      let(:container) { personal_snippet }

      it_behaves_like '#data checks'
    end

    context 'with project snippet' do
      let(:container) { project_snippet }

      it_behaves_like '#data checks'
    end
  end

  describe '#external_storage_error?' do
    shared_examples 'no error' do
      it do
        expect(blob.external_storage_error?).to be_falsey
      end
    end

    shared_examples 'returns error' do
      it do
        expect(blob.external_storage_error?).to be_truthy
      end
    end

    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true, container: container) }

      context 'when the project has LFS enabled' do
        context 'with project' do
          let(:container) { project }

          it_behaves_like 'no error'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns error'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'no error'
        end
      end

      context 'when the project does not have LFS enabled' do
        before do
          project.lfs_enabled = false
        end

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns error'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns error'
        end
      end
    end

    context 'if the blob is not stored in LFS' do
      let(:blob) { fake_blob(path: 'file.md', container: container) }

      context 'with project' do
        let(:container) { project }

        it_behaves_like 'no error'
      end

      context 'with personal snippet' do
        let(:container) { personal_snippet }

        it_behaves_like 'no error'
      end

      context 'with project snippet' do
        let(:container) { project_snippet }

        it_behaves_like 'no error'
      end
    end
  end

  describe '#stored_externally?' do
    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true) }

      shared_examples 'returns true' do
        it do
          expect(blob.stored_externally?).to be_truthy
        end
      end

      shared_examples 'returns false' do
        it do
          expect(blob.stored_externally?).to be_falsey
        end
      end

      context 'when the project has LFS enabled' do
        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns true'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns true'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns true'
        end
      end

      context 'when the project does not have LFS enabled' do
        before do
          project.lfs_enabled = false
        end

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns false'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns false'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns false'
        end
      end
    end

    context 'if the blob is not stored in LFS' do
      let(:blob) { fake_blob(path: 'file.md') }

      it 'returns false' do
        expect(blob.stored_externally?).to be_falsey
      end
    end
  end

  describe '#binary?' do
    shared_examples 'returns true' do
      it do
        expect(blob.binary?).to be_truthy
      end
    end

    shared_examples 'returns false' do
      it do
        expect(blob.binary?).to be_falsey
      end
    end

    context 'if the blob is stored externally' do
      let(:blob) { fake_blob(path: file, lfs: true) }

      context 'if the extension has a rich viewer' do
        context 'if the viewer is binary' do
          let(:file) { 'file.pdf' }

          context 'with project' do
            let(:container) { project }

            it_behaves_like 'returns true'
          end

          context 'with personal snippet' do
            let(:container) { personal_snippet }

            it_behaves_like 'returns true'
          end

          context 'with project snippet' do
            let(:container) { project_snippet }

            it_behaves_like 'returns true'
          end
        end

        context 'if the viewer is text-based' do
          let(:file) { 'file.md' }

          context 'with project' do
            let(:container) { project }

            it_behaves_like 'returns false'
          end

          context 'with personal snippet' do
            let(:container) { personal_snippet }

            it_behaves_like 'returns false'
          end

          context 'with project snippet' do
            let(:container) { project_snippet }

            it_behaves_like 'returns false'
          end
        end
      end

      context "if the extension doesn't have a rich viewer" do
        context 'if the extension has a text mime type' do
          context 'if the extension is for a programming language' do
            let(:file) { 'file.txt' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns false'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns false'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns false'
            end
          end

          context 'if the extension is not for a programming language' do
            let(:file) { 'file.ics' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns false'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns false'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns false'
            end
          end
        end

        context 'if the extension has a binary mime type' do
          context 'if the extension is for a programming language' do
            let(:file) { 'file.rb' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns false'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns false'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns false'
            end
          end

          context 'if the extension is not for a programming language' do
            let(:file) { 'file.exe' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns true'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns true'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns true'
            end
          end
        end

        context 'if the extension has an unknown mime type' do
          context 'if the extension is for a programming language' do
            let(:file) { 'file.ini' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns false'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns false'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns false'
            end
          end

          context 'if the extension is not for a programming language' do
            let(:file) { 'file.wtf' }

            context 'with project' do
              let(:container) { project }

              it_behaves_like 'returns true'
            end

            context 'with personal snippet' do
              let(:container) { personal_snippet }

              it_behaves_like 'returns true'
            end

            context 'with project snippet' do
              let(:container) { project_snippet }

              it_behaves_like 'returns true'
            end
          end
        end
      end
    end

    context 'if the blob is not stored externally' do
      context 'if the blob is binary' do
        let(:blob) { fake_blob(path: 'file.pdf', binary: true, container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns true'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns true'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns true'
        end
      end

      context 'if the blob is text-based' do
        let(:blob) { fake_blob(path: 'file.md', container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns false'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns false'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns false'
        end
      end
    end
  end

  describe '#extension' do
    it 'returns the extension' do
      blob = fake_blob(path: 'file.md')

      expect(blob.extension).to eq('md')
    end
  end

  describe '#file_type' do
    it 'returns the file type' do
      blob = fake_blob(path: 'README.md')

      expect(blob.file_type).to eq(:readme)
    end
  end

  describe '#simple_viewer' do
    context 'when the blob is empty' do
      it 'returns an empty viewer' do
        blob = fake_blob(data: '', size: 0)

        expect(blob.simple_viewer).to be_a(BlobViewer::Empty)
      end
    end

    context 'when the file represented by the blob is binary' do
      it 'returns a download viewer' do
        blob = fake_blob(binary: true)

        expect(blob.simple_viewer).to be_a(BlobViewer::Download)
      end
    end

    context 'when the file represented by the blob is text-based' do
      it 'returns a text viewer' do
        blob = fake_blob

        expect(blob.simple_viewer).to be_a(BlobViewer::Text)
      end
    end
  end

  describe '#rich_viewer' do
    context 'when the blob has an external storage error' do
      before do
        project.lfs_enabled = false
      end

      it 'returns nil' do
        blob = fake_blob(path: 'file.pdf', lfs: true)

        expect(blob.rich_viewer).to be_nil
      end
    end

    context 'when the blob is empty' do
      it 'returns nil' do
        blob = fake_blob(data: '')

        expect(blob.rich_viewer).to be_nil
      end
    end

    context 'when the blob is stored externally' do
      it 'returns a matching viewer' do
        blob = fake_blob(path: 'file.pdf', lfs: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::PDF)
      end
    end

    context 'when the blob is binary' do
      it 'returns a matching binary viewer' do
        blob = fake_blob(path: 'file.pdf', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::PDF)
      end
    end

    context 'when the blob is text-based' do
      it 'returns a matching text-based viewer' do
        blob = fake_blob(path: 'file.md')

        expect(blob.rich_viewer).to be_a(BlobViewer::Markup)
      end
    end

    context 'when the blob is video' do
      it 'returns a video viewer' do
        blob = fake_blob(path: 'file.mp4', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::Video)
      end
    end

    context 'when the blob is audio' do
      it 'returns an audio viewer' do
        blob = fake_blob(path: 'file.wav', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::Audio)
      end
    end
  end

  describe '#auxiliary_viewer' do
    context 'when the blob has an external storage error' do
      before do
        project.lfs_enabled = false
      end

      it 'returns nil' do
        blob = fake_blob(path: 'LICENSE', lfs: true)

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is empty' do
      it 'returns nil' do
        blob = fake_blob(data: '')

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is stored externally' do
      it 'returns a matching viewer' do
        blob = fake_blob(path: 'LICENSE', lfs: true)

        expect(blob.auxiliary_viewer).to be_a(BlobViewer::License)
      end
    end

    context 'when the blob is binary' do
      it 'returns nil' do
        blob = fake_blob(path: 'LICENSE', binary: true)

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is text-based' do
      it 'returns a matching text-based viewer' do
        blob = fake_blob(path: 'LICENSE')

        expect(blob.auxiliary_viewer).to be_a(BlobViewer::License)
      end
    end
  end

  describe '#rendered_as_text?' do
    shared_examples 'returns true' do
      it do
        expect(blob.rendered_as_text?(ignore_errors: ignore_errors)).to be_truthy
      end
    end

    shared_examples 'returns false' do
      it do
        expect(blob.rendered_as_text?(ignore_errors: ignore_errors)).to be_falsey
      end
    end

    context 'when ignoring errors' do
      let(:ignore_errors) { true }

      context 'when the simple viewer is text-based' do
        let(:blob) { fake_blob(path: 'file.md', size: 100.megabytes, container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns true'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns true'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns true'
        end
      end

      context 'when the simple viewer is binary' do
        let(:blob) { fake_blob(path: 'file.pdf', binary: true, size: 100.megabytes, container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns false'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns false'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns false'
        end
      end
    end

    context 'when not ignoring errors' do
      let(:ignore_errors) { false }

      context 'when the viewer has render errors' do
        let(:blob) { fake_blob(path: 'file.md', size: 100.megabytes, container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns false'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns false'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns false'
        end
      end

      context "when the viewer doesn't have render errors" do
        let(:blob) { fake_blob(path: 'file.md', container: container) }

        context 'with project' do
          let(:container) { project }

          it_behaves_like 'returns true'
        end

        context 'with personal snippet' do
          let(:container) { personal_snippet }

          it_behaves_like 'returns true'
        end

        context 'with project snippet' do
          let(:container) { project_snippet }

          it_behaves_like 'returns true'
        end
      end
    end
  end

  describe 'policy' do
    let(:project) { build(:project) }

    subject { described_class.new(fake_blob(path: 'foo'), project) }

    it 'works with policy' do
      expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_truthy
    end

    context 'when project is nil' do
      subject { described_class.new(fake_blob(path: 'foo')) }

      it 'does not err' do
        expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_falsey
      end
    end
  end
end
