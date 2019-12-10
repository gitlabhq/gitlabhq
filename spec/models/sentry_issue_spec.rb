# frozen_string_literal: true

require 'spec_helper'

describe SentryIssue do
  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    let!(:sentry_issue) { create(:sentry_issue) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_presence_of(:sentry_issue_identifier) }
  end
end
