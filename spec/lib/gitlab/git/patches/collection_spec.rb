# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Git::Patches::Collection do
  let(:patches_folder) { Rails.root.join('spec/fixtures/patchfiles') }
  let(:patch_content1) do
    File.read(File.join(patches_folder, "0001-This-does-not-apply-to-the-feature-branch.patch"))
  end

  let(:patch_content2) do
    File.read(File.join(patches_folder, "0001-A-commit-from-a-patch.patch"))
  end

  subject(:collection) { described_class.new([patch_content1, patch_content2]) }

  describe '#size' do
    it 'combines the size of the patches' do
      expect(collection.size).to eq(549.bytes + 424.bytes)
    end
  end

  describe '#valid_size?' do
    it 'is not valid if the total size is bigger than 2MB' do
      expect(collection).to receive(:size).and_return(2500.kilobytes)

      expect(collection).not_to be_valid_size
    end
  end
end
