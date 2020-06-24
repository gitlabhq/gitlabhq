# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileSizeValidator do
  let(:validator) { described_class.new(options) }
  let(:note) { create(:note) }
  let(:attachment) { AttachmentUploader.new(note) }

  describe 'options uses an integer' do
    let(:options) { { maximum: 10, attributes: { attachment: attachment } } }

    it 'attachment exceeds maximum limit' do
      allow(attachment).to receive(:size) { 100 }
      validator.validate_each(note, :attachment, attachment)
      expect(note.errors).to have_key(:attachment)
    end

    it 'attachment under maximum limit' do
      allow(attachment).to receive(:size) { 1 }
      validator.validate_each(note, :attachment, attachment)
      expect(note.errors).not_to have_key(:attachment)
    end
  end

  describe 'options uses a symbol' do
    let(:options) do
      {
        maximum: :max_attachment_size,
        attributes: { attachment: attachment }
      }
    end

    before do
      expect(note).to receive(:max_attachment_size) { 10 }
    end

    it 'attachment exceeds maximum limit' do
      allow(attachment).to receive(:size) { 100 }
      validator.validate_each(note, :attachment, attachment)
      expect(note.errors).to have_key(:attachment)
    end

    it 'attachment under maximum limit' do
      allow(attachment).to receive(:size) { 1 }
      validator.validate_each(note, :attachment, attachment)
      expect(note.errors).not_to have_key(:attachment)
    end
  end
end
