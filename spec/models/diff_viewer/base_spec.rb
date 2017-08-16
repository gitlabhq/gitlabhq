require 'spec_helper'

describe DiffViewer::Base do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

  let(:viewer_class) do
    Class.new(described_class) do
      include DiffViewer::ServerSide

      self.extensions = %w(jpg)
      self.binary = true
      self.collapse_limit = 1.megabyte
      self.size_limit = 5.megabytes
    end
  end

  let(:viewer) { viewer_class.new(diff_file) }

  describe '.can_render?' do
    context 'when the extension is supported' do
      let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      context 'when the binaryness matches' do
        it 'returns true' do
          expect(viewer_class.can_render?(diff_file)).to be_truthy
        end
      end

      context 'when the binaryness does not match' do
        before do
          allow(diff_file.old_blob).to receive(:binary?).and_return(false)
          allow(diff_file.new_blob).to receive(:binary?).and_return(false)
        end

        it 'returns false' do
          expect(viewer_class.can_render?(diff_file)).to be_falsey
        end
      end
    end

    context 'when the file type is supported' do
      let(:commit) { project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('LICENSE') }

      before do
        viewer_class.file_types = %i(license)
        viewer_class.binary = false
      end

      context 'when the binaryness matches' do
        it 'returns true' do
          expect(viewer_class.can_render?(diff_file)).to be_truthy
        end
      end

      context 'when the binaryness does not match' do
        before do
          allow(diff_file.old_blob).to receive(:binary?).and_return(true)
          allow(diff_file.new_blob).to receive(:binary?).and_return(true)
        end

        it 'returns false' do
          expect(viewer_class.can_render?(diff_file)).to be_falsey
        end
      end
    end

    context 'when the extension and file type are not supported' do
      it 'returns false' do
        expect(viewer_class.can_render?(diff_file)).to be_falsey
      end
    end

    context 'when the file was renamed and only the old blob is supported' do
      let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      before do
        allow(diff_file).to receive(:renamed_file?).and_return(true)
        allow(diff_file.new_blob).to receive(:extension).and_return('jpeg')
      end

      it 'returns false' do
        expect(viewer_class.can_render?(diff_file)).to be_falsey
      end
    end
  end

  describe '#collapsed?' do
    context 'when the combined blob size is larger than the collapse limit' do
      before do
        allow(diff_file.old_blob).to receive(:raw_size).and_return(512.kilobytes)
        allow(diff_file.new_blob).to receive(:raw_size).and_return(513.kilobytes)
      end

      it 'returns true' do
        expect(viewer.collapsed?).to be_truthy
      end
    end

    context 'when the combined blob size is smaller than the collapse limit' do
      it 'returns false' do
        expect(viewer.collapsed?).to be_falsey
      end
    end
  end

  describe '#too_large?' do
    context 'when the combined blob size is larger than the size limit' do
      before do
        allow(diff_file.old_blob).to receive(:raw_size).and_return(2.megabytes)
        allow(diff_file.new_blob).to receive(:raw_size).and_return(4.megabytes)
      end

      it 'returns true' do
        expect(viewer.too_large?).to be_truthy
      end
    end

    context 'when the blob size is smaller than the size limit' do
      it 'returns false' do
        expect(viewer.too_large?).to be_falsey
      end
    end
  end

  describe '#render_error' do
    context 'when the combined blob size is larger than the size limit' do
      before do
        allow(diff_file.old_blob).to receive(:raw_size).and_return(2.megabytes)
        allow(diff_file.new_blob).to receive(:raw_size).and_return(4.megabytes)
      end

      it 'returns :too_large' do
        expect(viewer.render_error).to eq(:too_large)
      end
    end

    context 'when the combined blob size is smaller than the size limit' do
      it 'returns nil' do
        expect(viewer.render_error).to be_nil
      end
    end
  end
end
