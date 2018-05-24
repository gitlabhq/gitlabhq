require 'spec_helper'

describe UserPreference do
  describe '#set_discussion_filter' do
    let(:issuable) { build_stubbed(:issue) }
    let(:user_preference) { create(:user_preference) }
    let(:only_comments) { described_class::DISCUSSION_FILTERS[:comments] }

    it 'returns updated discussion filter' do
      filter_name =
        user_preference.set_discussion_filter(only_comments, issuable)

      expect(filter_name).to eq(only_comments)
    end

    it 'updates discussion filter for issuable class' do
      user_preference.set_discussion_filter(only_comments, issuable)

      expect(user_preference.reload.issue_discussion_filter).to eq(only_comments)
    end
  end
end
