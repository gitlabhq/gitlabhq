# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffViewer::Image do
  describe '.can_render?' do
    let(:diff_file) { double(Gitlab::Diff::File) }
    let(:blob) { double(Gitlab::Git::Blob, binary_in_repo?: true, extension: 'png') }

    subject { described_class.can_render?(diff_file, verify_binary: false) }

    it 'returns false if both old and new blob are absent' do
      allow(diff_file).to receive(:old_blob) { nil }
      allow(diff_file).to receive(:new_blob) { nil }

      is_expected.to be_falsy
    end

    it 'returns true if the old blob is present' do
      allow(diff_file).to receive(:old_blob) { blob }
      allow(diff_file).to receive(:new_blob) { nil }

      is_expected.to be_truthy
    end

    it 'returns true if the new blob is present' do
      allow(diff_file).to receive(:old_blob) { nil }
      allow(diff_file).to receive(:new_blob) { blob }

      is_expected.to be_truthy
    end

    it 'returns true if both old and new blobs are present' do
      allow(diff_file).to receive(:old_blob) { blob }
      allow(diff_file).to receive(:new_blob) { blob }

      is_expected.to be_truthy
    end
  end
end
