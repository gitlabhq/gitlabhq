# encoding: utf-8
require 'rails_helper'

describe Blob do
  include FakeBlobHelpers

  let(:project) { build(:project, lfs_enabled: true) }

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '.lazy' do
    let(:project) { create(:project, :repository) }
    let(:commit) { project.commit_by(oid: 'e63f41fe459e62e1228fcef60d7189127aeba95a') }

    it 'fetches all blobs when the first is accessed' do
      changelog = described_class.lazy(project, commit.id, 'CHANGELOG')
      contributing = described_class.lazy(project, commit.id, 'CONTRIBUTING.md')

      expect(Gitlab::Git::Blob).to receive(:batch).once.and_call_original
      expect(Gitlab::Git::Blob).not_to receive(:find)

      # Access property so the values are loaded
      changelog.id
      contributing.id
    end
  end

  describe '#data' do
    context 'using a binary blob' do
      it 'returns the data as-is' do
        data = "\n\xFF\xB9\xC3"
        blob = fake_blob(binary: true, data: data)

        expect(blob.data).to eq(data)
      end
    end

    context 'using a text blob' do
      it 'converts the data to UTF-8' do
        blob = fake_blob(binary: false, data: "\n\xFF\xB9\xC3")

        expect(blob.data).to eq("\n���")
      end
    end
  end

  describe '#external_storage_error?' do
    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true) }

      context 'when the project has LFS enabled' do
        it 'returns false' do
          expect(blob.external_storage_error?).to be_falsey
        end
      end

      context 'when the project does not have LFS enabled' do
        before do
          project.lfs_enabled = false
        end

        it 'returns true' do
          expect(blob.external_storage_error?).to be_truthy
        end
      end
    end

    context 'if the blob is not stored in LFS' do
      let(:blob) { fake_blob(path: 'file.md') }

      it 'returns false' do
        expect(blob.external_storage_error?).to be_falsey
      end
    end
  end

  describe '#stored_externally?' do
    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true) }

      context 'when the project has LFS enabled' do
        it 'returns true' do
          expect(blob.stored_externally?).to be_truthy
        end
      end

      context 'when the project does not have LFS enabled' do
        before do
          project.lfs_enabled = false
        end

        it 'returns false' do
          expect(blob.stored_externally?).to be_falsey
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

  describe '#raw_binary?' do
    context 'if the blob is stored externally' do
      context 'if the extension has a rich viewer' do
        context 'if the viewer is binary' do
          it 'returns true' do
            blob = fake_blob(path: 'file.pdf', lfs: true)

            expect(blob.raw_binary?).to be_truthy
          end
        end

        context 'if the viewer is text-based' do
          it 'return false' do
            blob = fake_blob(path: 'file.md', lfs: true)

            expect(blob.raw_binary?).to be_falsey
          end
        end
      end

      context "if the extension doesn't have a rich viewer" do
        context 'if the extension has a text mime type' do
          context 'if the extension is for a programming language' do
            it 'returns false' do
              blob = fake_blob(path: 'file.txt', lfs: true)

              expect(blob.raw_binary?).to be_falsey
            end
          end

          context 'if the extension is not for a programming language' do
            it 'returns false' do
              blob = fake_blob(path: 'file.ics', lfs: true)

              expect(blob.raw_binary?).to be_falsey
            end
          end
        end

        context 'if the extension has a binary mime type' do
          context 'if the extension is for a programming language' do
            it 'returns false' do
              blob = fake_blob(path: 'file.rb', lfs: true)

              expect(blob.raw_binary?).to be_falsey
            end
          end

          context 'if the extension is not for a programming language' do
            it 'returns true' do
              blob = fake_blob(path: 'file.exe', lfs: true)

              expect(blob.raw_binary?).to be_truthy
            end
          end
        end

        context 'if the extension has an unknown mime type' do
          context 'if the extension is for a programming language' do
            it 'returns false' do
              blob = fake_blob(path: 'file.ini', lfs: true)

              expect(blob.raw_binary?).to be_falsey
            end
          end

          context 'if the extension is not for a programming language' do
            it 'returns true' do
              blob = fake_blob(path: 'file.wtf', lfs: true)

              expect(blob.raw_binary?).to be_truthy
            end
          end
        end
      end
    end

    context 'if the blob is not stored externally' do
      context 'if the blob is binary' do
        it 'returns true' do
          blob = fake_blob(path: 'file.pdf', binary: true)

          expect(blob.raw_binary?).to be_truthy
        end
      end

      context 'if the blob is text-based' do
        it 'return false' do
          blob = fake_blob(path: 'file.md')

          expect(blob.raw_binary?).to be_falsey
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
    context 'when ignoring errors' do
      context 'when the simple viewer is text-based' do
        it 'returns true' do
          blob = fake_blob(path: 'file.md', size: 100.megabytes)

          expect(blob.rendered_as_text?).to be_truthy
        end
      end

      context 'when the simple viewer is binary' do
        it 'returns false' do
          blob = fake_blob(path: 'file.pdf', binary: true, size: 100.megabytes)

          expect(blob.rendered_as_text?).to be_falsey
        end
      end
    end

    context 'when not ignoring errors' do
      context 'when the viewer has render errors' do
        it 'returns false' do
          blob = fake_blob(path: 'file.md', size: 100.megabytes)

          expect(blob.rendered_as_text?(ignore_errors: false)).to be_falsey
        end
      end

      context "when the viewer doesn't have render errors" do
        it 'returns true' do
          blob = fake_blob(path: 'file.md')

          expect(blob.rendered_as_text?(ignore_errors: false)).to be_truthy
        end
      end
    end
  end
end
