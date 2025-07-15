# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNoteMetadata, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
    it { is_expected.to belong_to(:description_version) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:note) }

    context 'when action type is invalid' do
      subject do
        build(:system_note_metadata, note: build(:note), action: 'invalid_type')
      end

      it { is_expected.to be_invalid }
    end

    %i[merge timeline_event requested_changes].each do |action|
      context 'when action type is valid' do
        subject do
          build(:system_note_metadata, note: build(:note), action: action)
        end

        it { is_expected.to be_valid }
      end
    end

    context 'when importing' do
      subject do
        build(:system_note_metadata, note: nil, action: 'merge', importing: true)
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'scopes' do
    describe '.for_notes' do
      let_it_be(:notes) { create_list(:note, 2) }
      let_it_be(:metadata1) { create(:system_note_metadata, note: notes[0]) }
      let_it_be(:metadata2) { create(:system_note_metadata, note: notes[1]) }

      it { expect(described_class.for_notes(notes)).to match_array([metadata1, metadata2]) }
      it { expect(described_class.for_notes(notes.map(&:id))).to match_array([metadata1, metadata2]) }
      it { expect(described_class.for_notes(::Note.id_in(notes))).to match_array([metadata1, metadata2]) }
    end
  end

  describe '#about_relation?' do
    let(:note) { create(:note) }
    let(:system_note_metadata) { build(:system_note_metadata, note: note) }

    context 'when action is in cross_reference_types_with_branch' do
      SystemNoteMetadata::WORK_ITEMS_CROSS_REFERENCE.each do |action_type|
        it "returns true for action '#{action_type}'" do
          system_note_metadata.action = action_type

          expect(system_note_metadata.about_relation?).to be true
        end
      end
    end

    context 'when action is not in cross_reference_types_with_branch' do
      let(:non_cross_reference_actions) do
        SystemNoteMetadata::ICON_TYPES - SystemNoteMetadata::WORK_ITEMS_CROSS_REFERENCE
      end

      it 'returns false for actions not in cross reference types' do
        non_cross_reference_actions.each do |action_type|
          system_note_metadata.action = action_type

          expect(system_note_metadata.about_relation?).to be false
        end
      end

      it 'returns false for custom action not in any predefined types' do
        system_note_metadata.action = 'custom_action'

        expect(system_note_metadata.about_relation?).to be false
      end
    end
  end
end
