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
  let(:stitcher) { described_class.new(diff_msgs, lookahead: true) }

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

  describe '#single_file?' do
    def single_file_per_yield
      stitcher.map { stitcher.single_file? }
    end

    it 'is false for every patch of a multi-patch stream' do
      expect(single_file_per_yield).to eq([false, false, false])
    end

    context 'with a single patch in the stream' do
      let(:diff_msgs) { [msg_1] }

      it 'is true when that patch is yielded' do
        expect(single_file_per_yield).to eq([true])
      end
    end

    context 'when the look-ahead is disabled' do
      let(:stitcher) { described_class.new(diff_msgs, lookahead: false) }

      # Without the look-ahead the count is of patches seen so far, which is
      # why the first file of a multi-file diff used to auto-expand.
      it 'reports the first patch of a multi-patch stream as single' do
        expect(single_file_per_yield).to eq([true, false, false])
      end

      context 'with a single patch in the stream' do
        let(:diff_msgs) { [msg_1] }

        it 'is true' do
          expect(single_file_per_yield).to eq([true])
        end
      end
    end
  end

  describe 'holding each patch until the next arrives' do
    # The real response is consumed once, unlike the Array the other examples
    # wrap, so a held patch that got dropped would be lost rather than re-read.
    let(:consumed_once) do
      remaining = diff_msgs.dup
      stream = Object.new
      stream.define_singleton_method(:each) do |&block|
        block.call(remaining.shift) while remaining.any?
      end
      stream
    end

    it 'yields every patch exactly once, in order' do
      expect(stitcher.map(&:to_path)).to eq([diff_1.to_path, diff_2.to_path, diff_3.to_path])
    end

    it 'does not lose the held patch when a consumer stops early' do
      stitcher = described_class.new(consumed_once, lookahead: true)

      first = stitcher.first # stops iterating after one patch

      expect([first.to_path] + stitcher.map(&:to_path))
        .to eq([diff_1.to_path, diff_2.to_path, diff_3.to_path])
    end

    context 'when the look-ahead is disabled' do
      it 'still yields every patch exactly once, in order' do
        stitcher = described_class.new(consumed_once, lookahead: false)

        expect(stitcher.map(&:to_path)).to eq([diff_1.to_path, diff_2.to_path, diff_3.to_path])
      end
    end
  end
end
