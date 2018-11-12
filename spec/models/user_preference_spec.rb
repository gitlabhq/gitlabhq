# frozen_string_literal: true

require 'spec_helper'

describe UserPreference do
  describe '#set_notes_filter' do
    let(:issuable) { build_stubbed(:issue) }
    let(:user_preference) { create(:user_preference) }

    shared_examples 'setting system notes' do
      it 'returns updated discussion filter' do
        filter_name =
          user_preference.set_notes_filter(filter, issuable)

        expect(filter_name).to eq(filter)
      end

      it 'updates discussion filter for issuable class' do
        user_preference.set_notes_filter(filter, issuable)

        expect(user_preference.reload.issue_notes_filter).to eq(filter)
      end
    end

    context 'when filter is set to all notes' do
      let(:filter) { described_class::NOTES_FILTERS[:all_notes] }

      it_behaves_like 'setting system notes'
    end

    context 'when filter is set to only comments' do
      let(:filter) { described_class::NOTES_FILTERS[:only_comments] }

      it_behaves_like 'setting system notes'
    end

    context 'when filter is set to only activity' do
      let(:filter) { described_class::NOTES_FILTERS[:only_activity] }

      it_behaves_like 'setting system notes'
    end

    context 'when notes_filter parameter is invalid' do
      let(:only_comments) { described_class::NOTES_FILTERS[:only_comments] }

      it 'returns the current notes filter' do
        user_preference.set_notes_filter(only_comments, issuable)

        expect(user_preference.set_notes_filter(9999, issuable)).to eq(only_comments)
      end
    end
  end
end
