# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::FileSizeCheck::AnyOversizedBlob, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:any_blob) do
    described_class.new(
      project: project,
      changes: [{ newrev: 'bf12d2567099e26f59692896f73ac819bae45b00' }],
      file_size_limit_megabytes: 1)
  end

  describe '#find!' do
    subject { any_blob.find! }

    # SHA of the 2-mb-file branch
    let(:newrev)    { 'bf12d2567099e26f59692896f73ac819bae45b00' }
    let(:timeout) { nil }

    before do
      # Delete branch so Repository#new_blobs can return results
      project.repository.delete_branch('2-mb-file')
    end

    it 'returns the blob exceeding the file size limit' do
      blob = subject
      expect(blob).to be_kind_of(Gitlab::Git::Blob)
      expect(blob.path).to eq('file.bin')
    end
  end
end
