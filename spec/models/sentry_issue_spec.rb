# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentryIssue do
  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    let!(:sentry_issue) { create(:sentry_issue) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_presence_of(:sentry_issue_identifier) }

    it 'allows duplicated sentry_issue_identifier' do
      duplicate_sentry_issue = build(:sentry_issue, sentry_issue_identifier: sentry_issue.sentry_issue_identifier)

      expect(duplicate_sentry_issue).to be_valid
    end

    it 'validates uniqueness of sentry_issue_identifier per project' do
      second_issue = create(:issue, project: sentry_issue.issue.project)
      duplicate_sentry_issue = build(:sentry_issue, issue: second_issue, sentry_issue_identifier: sentry_issue.sentry_issue_identifier)

      expect(duplicate_sentry_issue).to be_invalid
      expect(duplicate_sentry_issue.errors.full_messages.first).to include('is already associated')
    end

    describe 'when importing' do
      subject { create(:sentry_issue, importing: true) }

      it { is_expected.not_to validate_presence_of(:issue) }
    end
  end

  describe 'callbacks' do
    context 'after create commit do' do
      it 'updates Sentry with a reciprocal link on creation' do
        issue = create(:issue)

        expect(ErrorTrackingIssueLinkWorker).to receive(:perform_async).with(issue.id)

        create(:sentry_issue, issue: issue)
      end
    end
  end

  describe '.for_project_and_identifier' do
    it 'finds the most recent per project and sentry_issue_identifier' do
      sentry_issue = create(:sentry_issue)
      create(:sentry_issue)
      project = sentry_issue.issue.project
      sentry_issue_3 = build(:sentry_issue, issue: create(:issue, project: project), sentry_issue_identifier: sentry_issue.sentry_issue_identifier)
      sentry_issue_3.save!(validate: false)

      result = described_class.for_project_and_identifier(project, sentry_issue.sentry_issue_identifier)

      expect(result).to eq(sentry_issue_3)
    end
  end
end
