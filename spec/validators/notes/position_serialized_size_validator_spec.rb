# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::PositionSerializedSizeValidator, feature_category: :code_review_workflow do
  let(:diff_refs) { nil }

  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 14,
      line_range: nil,
      diff_refs: diff_refs
    )
  end

  let(:note) { build(:diff_note_on_merge_request, position: position) }

  subject(:validator) do
    described_class.new(attributes: [:position], max_bytesize: 50.kilobytes)
  end

  it 'adds no error when data is small' do
    note.position = { foo: 'bar' }
    validator.validate_each(note, :position, note.position)
    expect(note.errors[:position]).to be_empty
  end

  context "when data is large" do
    let(:diff_refs) do
      Gitlab::Diff::DiffRefs.new(
        base_sha: "not_existing_sha",
        head_sha: "existing_sha",
        start_sha: 'x' * 51.kilobytes
      )
    end

    it 'adds an error when data is too large' do
      validator.validate_each(note, :position, note.position)

      expect(note.errors[:position]).to include(/too large/)
    end

    context "when the field has changed and the record is not new" do
      before do
        allow(note).to receive(:new_record?).and_return(false)
      end

      it 'adds an error when data is too large' do
        validator.validate_each(note, :position, note.position)

        expect(note.errors[:position]).to include(/too large/)
      end
    end

    context "when the field hasn't changed" do
      before do
        allow(note).to receive(:new_record?).and_return(false)
        allow(note).to receive(:will_save_change_to_attribute?).with(:position).and_return(false)
      end

      it "skips validation" do
        validator.validate_each(note, :position, note.position)

        expect(note.errors[:position]).to be_empty
      end
    end
  end
end
