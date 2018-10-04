# frozen_string_literal: true

require 'spec_helper'

describe UserPreference do
  describe '#set_notes_filter' do
    let(:issuable) { build_stubbed(:issue) }
    let(:user_preference) { create(:user_preference) }
    let(:only_comments) { described_class::NOTES_FILTERS[:only_comments] }

    it 'returns updated discussion filter' do
      filter_name =
        user_preference.set_notes_filter(only_comments, issuable)

      expect(filter_name).to eq(only_comments)
    end

    it 'updates discussion filter for issuable class' do
      user_preference.set_notes_filter(only_comments, issuable)

      expect(user_preference.reload.issue_notes_filter).to eq(only_comments)
    end

    context 'when notes_filter parameter is invalid' do
      it 'returns the current notes filter' do
        user_preference.set_notes_filter(only_comments, issuable)

        expect(user_preference.set_notes_filter(9999, issuable)).to eq(only_comments)
      end
    end
  end
end
