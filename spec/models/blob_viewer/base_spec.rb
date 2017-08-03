require 'spec_helper'

describe BlobViewer::Base do
  include FakeBlobHelpers

  let(:project) { build(:project) }

  let(:viewer_class) do
    Class.new(described_class) do
      include BlobViewer::ServerSide

      self.extensions = %w(pdf)
      self.binary = true
      self.collapse_limit = 1.megabyte
      self.size_limit = 5.megabytes
    end
  end

  let(:viewer) { viewer_class.new(blob) }

  describe '.can_render?' do
    context 'when the extension is supported' do
      context 'when the binaryness matches' do
        let(:blob) { fake_blob(path: 'file.pdf', binary: true) }

        it 'returns true' do
          expect(viewer_class.can_render?(blob)).to be_truthy
        end
      end

      context 'when the binaryness does not match' do
        let(:blob) { fake_blob(path: 'file.pdf', binary: false) }

        it 'returns false' do
          expect(viewer_class.can_render?(blob)).to be_falsey
        end
      end
    end

    context 'when the file type is supported' do
      before do
        viewer_class.file_types = %i(license)
        viewer_class.binary = false
      end

      context 'when the binaryness matches' do
        let(:blob) { fake_blob(path: 'LICENSE', binary: false) }

        it 'returns true' do
          expect(viewer_class.can_render?(blob)).to be_truthy
        end
      end

      context 'when the binaryness does not match' do
        let(:blob) { fake_blob(path: 'LICENSE', binary: true) }

        it 'returns false' do
          expect(viewer_class.can_render?(blob)).to be_falsey
        end
      end
    end

    context 'when the extension and file type are not supported' do
      let(:blob) { fake_blob(path: 'file.txt') }

      it 'returns false' do
        expect(viewer_class.can_render?(blob)).to be_falsey
      end
    end
  end

  describe '#collapsed?' do
    context 'when the blob size is larger than the collapse limit' do
      let(:blob) { fake_blob(path: 'file.pdf', size: 2.megabytes) }

      it 'returns true' do
        expect(viewer.collapsed?).to be_truthy
      end
    end

    context 'when the blob size is smaller than the collapse limit' do
      let(:blob) { fake_blob(path: 'file.pdf', size: 10.kilobytes) }

      it 'returns false' do
        expect(viewer.collapsed?).to be_falsey
      end
    end
  end

  describe '#too_large?' do
    context 'when the blob size is larger than the size limit' do
      let(:blob) { fake_blob(path: 'file.pdf', size: 10.megabytes) }

      it 'returns true' do
        expect(viewer.too_large?).to be_truthy
      end
    end

    context 'when the blob size is smaller than the size limit' do
      let(:blob) { fake_blob(path: 'file.pdf', size: 2.megabytes) }

      it 'returns false' do
        expect(viewer.too_large?).to be_falsey
      end
    end
  end

  describe '#render_error' do
    context 'when the blob is expanded' do
      before do
        blob.expand!
      end

      context 'when the blob size is larger than the size limit' do
        let(:blob) { fake_blob(path: 'file.pdf', size: 10.megabytes) }

        it 'returns :too_large' do
          expect(viewer.render_error).to eq(:too_large)
        end
      end

      context 'when the blob size is smaller than the size limit' do
        let(:blob) { fake_blob(path: 'file.pdf', size: 2.megabytes) }

        it 'returns nil' do
          expect(viewer.render_error).to be_nil
        end
      end
    end

    context 'when not expanded' do
      context 'when the blob size is larger than the collapse limit' do
        let(:blob) { fake_blob(path: 'file.pdf', size: 2.megabytes) }

        it 'returns :collapsed' do
          expect(viewer.render_error).to eq(:collapsed)
        end
      end

      context 'when the blob size is smaller than the collapse limit' do
        let(:blob) { fake_blob(path: 'file.pdf', size: 10.kilobytes) }

        it 'returns nil' do
          expect(viewer.render_error).to be_nil
        end
      end
    end
  end
end
