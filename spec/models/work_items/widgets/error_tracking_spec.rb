# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::ErrorTracking, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:sentry_issue) { create(:sentry_issue, issue: work_item) }

  describe '.type' do
    it { expect(described_class.type).to eq(:error_tracking) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:error_tracking) }
  end

  describe '.sentry_issue' do
    it { expect(described_class.new(work_item).sentry_issue).to eq(sentry_issue) }
  end

  describe '.sentry_issue_identifier' do
    it { expect(described_class.new(work_item).sentry_issue_identifier).to eq(sentry_issue.sentry_issue_identifier) }
  end
end
