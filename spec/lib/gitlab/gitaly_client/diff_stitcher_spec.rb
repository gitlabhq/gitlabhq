require 'spec_helper'

describe Gitlab::GitalyClient::DiffStitcher do
  describe 'enumeration' do
    it 'combines segregated diff messages together' do
      diff_1 = OpenStruct.new(
        to_path: ".gitmodules",
        from_path: ".gitmodules",
        old_mode: 0100644,
        new_mode: 0100644,
        from_id: '357406f3075a57708d0163752905cc1576fceacc',
        to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
        patch: 'a' * 100
      )
      diff_2 = OpenStruct.new(
        to_path: ".gitignore",
        from_path: ".gitignore",
        old_mode: 0100644,
        new_mode: 0100644,
        from_id: '357406f3075a57708d0163752905cc1576fceacc',
        to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
        patch: 'a' * 200
      )
      diff_3 = OpenStruct.new(
        to_path: "README",
        from_path: "README",
        old_mode: 0100644,
        new_mode: 0100644,
        from_id: '357406f3075a57708d0163752905cc1576fceacc',
        to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
        patch: 'a' * 100
      )

      msg_1 = OpenStruct.new(diff_1.to_h.except(:patch))
      msg_1.raw_patch_data = diff_1.patch
      msg_1.end_of_patch = true

      msg_2 = OpenStruct.new(diff_2.to_h.except(:patch))
      msg_2.raw_patch_data = diff_2.patch[0..100]
      msg_2.end_of_patch = false

      msg_3 = OpenStruct.new(raw_patch_data: diff_2.patch[101..-1], end_of_patch: true)

      msg_4 = OpenStruct.new(diff_3.to_h.except(:patch))
      msg_4.raw_patch_data = diff_3.patch
      msg_4.end_of_patch = true

      diff_msgs = [msg_1, msg_2, msg_3, msg_4]

      expected_diffs = [
        Gitlab::GitalyClient::Diff.new(diff_1.to_h),
        Gitlab::GitalyClient::Diff.new(diff_2.to_h),
        Gitlab::GitalyClient::Diff.new(diff_3.to_h)
      ]

      expect(described_class.new(diff_msgs).to_a).to eq(expected_diffs)
    end
  end
end
