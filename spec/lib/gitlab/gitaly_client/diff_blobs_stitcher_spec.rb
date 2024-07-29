# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::DiffBlobsStitcher, feature_category: :gitaly do
  describe 'enumeration' do
    let(:message) { Struct.new(:left_blob_id, :right_blob_id, :patch, :status, :binary, :over_patch_bytes_limit) }

    it 'combines segregated diff blob messages together' do
      messages = [
        message.new(
          '357406f3075a57708d0163752905cc1576fceacc',
          '8e5177d718c561d36efde08bad36b43687ee6bf0',
          'a' * 100,
          :STATUS_INCOMPLETE,
          false,
          false
        ),
        message.new(
          '357406f3075a57708d0163752905cc1576fceacc',
          '8e5177d718c561d36efde08bad36b43687ee6bf0',
          'a' * 100,
          :STATUS_END_OF_PATCH,
          false,
          false
        ),
        message.new(
          '8f2e9b1c4d7a3f5e6b0d2c8a9f1e3d5b7c4a6e8d',
          '3a1d9c7b5f2e8d4a6c0b3e9f1d7a5c2b8e4f6a0',
          'b' * 100,
          :STATUS_END_OF_PATCH,
          false,
          false
        )
      ]

      diff_blobs = described_class.new(messages).to_a

      expect(diff_blobs.size).to eq(2)

      expect(diff_blobs.first.left_blob_id).to eq('357406f3075a57708d0163752905cc1576fceacc')
      expect(diff_blobs.first.right_blob_id).to eq('8e5177d718c561d36efde08bad36b43687ee6bf0')
      expect(diff_blobs.first.patch).to eq('a' * 200)
      expect(diff_blobs.first.status).to eq(:STATUS_END_OF_PATCH)
      expect(diff_blobs.first.binary).to eq(false)
      expect(diff_blobs.first.over_patch_bytes_limit).to eq(false)

      expect(diff_blobs.last.left_blob_id).to eq('8f2e9b1c4d7a3f5e6b0d2c8a9f1e3d5b7c4a6e8d')
      expect(diff_blobs.last.right_blob_id).to eq('3a1d9c7b5f2e8d4a6c0b3e9f1d7a5c2b8e4f6a0')
      expect(diff_blobs.last.patch).to eq('b' * 100)
      expect(diff_blobs.last.status).to eq(:STATUS_END_OF_PATCH)
      expect(diff_blobs.last.binary).to eq(false)
      expect(diff_blobs.last.over_patch_bytes_limit).to eq(false)
    end
  end
end
