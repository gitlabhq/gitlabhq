# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::IssueTrackerData, feature_category: :integrations do
  it_behaves_like Integrations::BaseDataFields

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:issues_url, :new_issue_url, :project_url) }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:project_url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:issues_url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:new_issue_url).is_at_most(2048) }

    it 'does not invalidate existing records' do
      issue_tracker_data = create(:issue_tracker_data)

      issue_tracker_data.assign_attributes(
        project_url: 'A' * 3000,
        issues_url: 'B' * 3000,
        new_issue_url: 'C' * 3000
      )

      issue_tracker_data.save!(validate: false)

      expect(issue_tracker_data.reload).to be_valid
    end
  end
end
