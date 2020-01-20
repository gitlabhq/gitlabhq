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
    let!(:sentry_issue) { create(:sentry_issue) }
    let(:project) { sentry_issue.issue.project }
    let(:identifier) { sentry_issue.sentry_issue_identifier }
    let!(:second_sentry_issue) { create(:sentry_issue) }

    subject { described_class.for_project_and_identifier(project, identifier) }

    it { is_expected.to eq(sentry_issue) }
  end
end
