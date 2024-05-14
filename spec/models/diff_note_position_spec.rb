# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffNotePosition, type: :model, feature_category: :code_review_workflow do
  describe '.create_or_update_by' do
    context 'when a diff note' do
      let(:note) { create(:diff_note_on_merge_request) }
      let(:diff_position) { build(:diff_position) }
      let(:line_code) { 'bd4b7bfff3a247ccf6e3371c41ec018a55230bcc_534_521' }
      let(:diff_note_position) { note.diff_note_positions.first }
      let(:params) { { diff_type: :head, line_code: line_code, position: diff_position } }

      context 'does not have a diff note position' do
        it 'creates a diff note position' do
          described_class.create_or_update_for(note, params)

          expect(diff_note_position.position).to eq(diff_position)
          expect(diff_note_position.line_code).to eq(line_code)
          expect(diff_note_position.diff_content_type).to eq('text')
        end
      end

      context 'has a diff note position' do
        it 'updates the existing diff note position' do
          create(:diff_note_position, note: note)
          described_class.create_or_update_for(note, params)

          expect(note.diff_note_positions.size).to eq(1)
          expect(diff_note_position.position).to eq(diff_position)
          expect(diff_note_position.line_code).to eq(line_code)
        end
      end
    end
  end

  it 'unique by note_id and diff type' do
    existing_diff_note_position = create(:diff_note_position)
    diff_note_position = build(:diff_note_position, note: existing_diff_note_position.note)

    expect { diff_note_position.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'accepts a line_range attribute' do
    diff_note_position = build(:diff_note_position)

    expect(diff_note_position).to respond_to(:line_range)
    expect(diff_note_position).to respond_to(:line_range=)
  end
end
