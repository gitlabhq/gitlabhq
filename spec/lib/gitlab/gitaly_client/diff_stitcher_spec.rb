# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::DiffStitcher do
  let(:diff_1) do
    OpenStruct.new(
      to_path: ".gitmodules",
      from_path: ".gitmodules",
      old_mode: 0100644,
      new_mode: 0100644,
      from_id: '357406f3075a57708d0163752905cc1576fceacc',
      to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
      patch: 'a' * 100
    )
  end

  let(:diff_2) do
    OpenStruct.new(
      to_path: ".gitignore",
      from_path: ".gitignore",
      old_mode: 0100644,
      new_mode: 0100644,
      from_id: '357406f3075a57708d0163752905cc1576fceacc',
      to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
      patch: 'a' * 200
    )
  end

  let(:diff_3) do
    OpenStruct.new(
      to_path: "README",
      from_path: "README",
      old_mode: 0100644,
      new_mode: 0100644,
      from_id: '357406f3075a57708d0163752905cc1576fceacc',
      to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
      patch: 'a' * 100
    )
  end

  let(:msg_1) do
    msg = OpenStruct.new(diff_1.to_h.except(:patch))
    msg.raw_patch_data = diff_1.patch
    msg.end_of_patch = true
    msg
  end

  let(:msg_2) do
    msg = OpenStruct.new(diff_2.to_h.except(:patch))
    msg.raw_patch_data = diff_2.patch[0..100]
    msg.end_of_patch = false
    msg
  end

  let(:msg_3) do
    OpenStruct.new(raw_patch_data: diff_2.patch[101..], end_of_patch: true)
  end

  let(:msg_4) do
    msg = OpenStruct.new(diff_3.to_h.except(:patch))
    msg.raw_patch_data = diff_3.patch
    msg.end_of_patch = true
    msg
  end

  let(:diff_msgs) { [msg_1, msg_2, msg_3, msg_4] }
  let(:stitcher) { described_class.new(diff_msgs) }

  describe 'enumeration' do
    it 'combines segregated diff messages together' do
      expected_diffs = [
        Gitlab::GitalyClient::Diff.new(diff_1.to_h),
        Gitlab::GitalyClient::Diff.new(diff_2.to_h),
        Gitlab::GitalyClient::Diff.new(diff_3.to_h)
      ]

      expect(stitcher.to_a).to eq(expected_diffs)
    end
  end

  describe '#size' do
    it 'returns the count of enumerated diffs' do
      # Before enumeration, size is 0
      expect(stitcher.size).to eq(0)

      # After enumeration, size is 3
      expect(stitcher).to all(be_present)
      expect(stitcher.size).to eq(3)
    end

    it 'accumulates diff count across enumerations' do
      expect(stitcher).to all(be_present)
      expect(stitcher.size).to eq(3)

      # Second enumeration adds to the count
      expect(stitcher).to all(be_present)
      expect(stitcher.size).to eq(6)
    end
  end
end
