# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Git::Patches::Patch do
  let(:patches_folder) { Rails.root.join('spec/fixtures/patchfiles') }
  let(:patch_content) do
    File.read(File.join(patches_folder, "0001-This-does-not-apply-to-the-feature-branch.patch"))
  end

  let(:patch) { described_class.new(patch_content) }

  describe '#size' do
    it 'is correct' do
      expect(patch.size).to eq(549.bytes)
    end
  end
end
