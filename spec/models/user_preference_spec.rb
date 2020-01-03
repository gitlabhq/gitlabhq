# frozen_string_literal: true

require 'spec_helper'

describe UserPreference do
  let(:user_preference) { create(:user_preference) }

  describe 'notes filters global keys' do
    it 'contains expected values' do
      expect(UserPreference::NOTES_FILTERS.keys).to match_array([:all_notes, :only_comments, :only_activity])
    end
  end

  describe '#set_notes_filter' do
    let(:issuable) { build_stubbed(:issue) }

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

  describe 'sort_by preferences' do
    shared_examples_for 'a sort_by preference' do
      it 'allows nil sort fields' do
        user_preference.update(attribute => nil)

        expect(user_preference).to be_valid
      end
    end

    context 'merge_requests_sort attribute' do
      let(:attribute) { :merge_requests_sort }

      it_behaves_like 'a sort_by preference'
    end

    context 'issues_sort attribute' do
      let(:attribute) { :issues_sort }

      it_behaves_like 'a sort_by preference'
    end
  end

  describe '#timezone' do
    it 'returns server time as default' do
      expect(user_preference.timezone).to eq(Time.zone.tzinfo.name)
    end
  end
end
