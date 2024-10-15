# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffViewer::Base do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

  let(:viewer_class) do
    Class.new(described_class) do
      include DiffViewer::ServerSide

      self.extensions = %w[jpg]
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
        let(:commit) { project.commit_by(oid: 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
        let(:diff_file) { commit.diffs.diff_file_with_new_path('Gemfile.zip') }

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
      let(:commit) { project.commit_by(oid: '2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:diff_file) { commit.diffs.diff_file_with_new_path('files/images/6049019_460s.jpg') }

      before do
        allow(diff_file).to receive(:renamed_file?).and_return(true)
        viewer_class.extensions = %w[notjpg]
      end

      it 'returns false' do
        expect(viewer_class.can_render?(diff_file)).to be_falsey
      end
    end
  end

  describe '#collapsed?' do
    context 'when the combined blob size is larger than the collapse limit' do
      before do
        allow(diff_file).to receive(:raw_size).and_return(1025.kilobytes)
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
        allow(diff_file).to receive(:raw_size).and_return(6.megabytes)
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

  describe '#expandable?' do
    subject(:expandable) { viewer.expandable? }

    let(:too_large) { false }
    let(:text) { true }

    before do
      allow(viewer).to receive(:too_large?).and_return(too_large)
      allow(viewer).to receive(:text?).and_return(text)
    end

    it 'is expandable' do
      expect(expandable).to be_truthy
    end

    context 'when it is too large' do
      let(:too_large) { true }

      it 'is not expandable' do
        expect(expandable).to be_falsey
      end
    end

    context 'when it is not text' do
      let(:text) { false }

      it 'is not expandable' do
        expect(expandable).to be_falsey
      end
    end
  end

  describe '#generated?' do
    before do
      allow(diff_file).to receive(:generated?).and_return(generated)
    end

    context 'when the diff file is generated' do
      let(:generated) { true }

      it 'returns true' do
        expect(viewer.generated?).to be_truthy
      end
    end

    context 'when the diff file is not generated' do
      let(:generated) { false }

      it 'returns true' do
        expect(viewer.generated?).to be_falsey
      end
    end
  end

  describe '#render_error' do
    context 'when the combined blob size is larger than the size limit' do
      before do
        allow(diff_file).to receive(:raw_size).and_return(6.megabytes)
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

  describe '#render_error_message' do
    it 'returns nothing when no render_error' do
      expect(viewer.render_error).to be_nil
      expect(viewer.render_error_message).to be_nil
    end

    context 'when render_error error' do
      before do
        allow(viewer).to receive(:render_error).and_return(:too_large)
      end

      it 'returns an error message' do
        expect(viewer.render_error_message).to include('it is too large')
      end

      it 'includes a "view the blob" link' do
        expect(viewer.render_error_message).to include('view the blob')
      end
    end
  end
end
