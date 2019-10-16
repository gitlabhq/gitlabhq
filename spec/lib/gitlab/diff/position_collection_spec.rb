# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::PositionCollection do
  let(:merge_request) { build(:merge_request) }

  def build_text_position(attrs = {})
    attributes = {
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    }.merge(attrs)

    Gitlab::Diff::Position.new(attributes)
  end

  def build_image_position(attrs = {})
    attributes = {
      old_path: "files/images/any_image.png",
      new_path: "files/images/any_image.png",
      width: 10,
      height: 10,
      x: 1,
      y: 1,
      diff_refs: merge_request.diff_refs,
      position_type: "image"
    }.merge(attrs)

    Gitlab::Diff::Position.new(attributes)
  end

  let(:text_position) { build_text_position }
  let(:folded_text_position) { build_text_position(old_line: 1, new_line: 1) }
  let(:image_position) { build_image_position }
  let(:invalid_position) { 'a position' }
  let(:head_sha) { merge_request.diff_head_sha }

  let(:collection) do
    described_class.new([text_position, folded_text_position, image_position, invalid_position], head_sha)
  end

  describe '#to_a' do
    it 'returns all positions that are Gitlab::Diff::Position' do
      expect(collection.to_a).to eq([text_position, folded_text_position, image_position])
    end
  end

  describe '#unfoldable' do
    it 'returns unfoldable diff positions' do
      expect(collection.unfoldable).to eq([folded_text_position])
    end

    context 'when given head_sha does not match with positions head_sha' do
      let(:head_sha) { 'unknown' }

      it 'returns no position' do
        expect(collection.unfoldable).to be_empty
      end
    end

    context 'when given head_sha is nil' do
      let(:head_sha) { nil }

      it 'returns unfoldable diff positions unfiltered by head_sha' do
        expect(collection.unfoldable).to eq([folded_text_position])
      end
    end
  end

  describe '#concat' do
    let(:new_text_position) { build_text_position(old_line: 1, new_line: 1) }

    it 'returns a Gitlab::Diff::Position' do
      expect(collection.concat([new_text_position])).to be_a(described_class)
    end

    it 'concatenates the new position to the collection' do
      collection.concat([new_text_position])

      expect(collection.to_a).to eq([text_position, folded_text_position, image_position, new_text_position])
    end
  end
end
