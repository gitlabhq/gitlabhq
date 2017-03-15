require 'spec_helper'

describe SystemNoteMetadata, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:note) }

    context 'when icon type is invalid' do
      subject do
        build(:system_note_metadata, note: build(:note), icon: 'invalid_type' )
      end

      it { is_expected.to be_invalid }
    end

    context 'when icon type is valid' do
      subject do
        build(:system_note_metadata, note: build(:note), icon: 'merge' )
      end

      it { is_expected.to be_valid }
    end
  end
end
