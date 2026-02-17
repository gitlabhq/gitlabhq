# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraTrackerData, feature_category: :integrations do
  it_behaves_like Integrations::BaseDataFields

  describe 'deployment_type' do
    specify do
      is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment)
    end
  end

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:api_url, :password, :url, :username) }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:api_url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:username).is_at_most(2048) }
    it { is_expected.to validate_length_of(:password).is_at_most(2048) }

    it 'does not invalidate existing records' do
      jira_tracker_data = create(:jira_tracker_data)

      jira_tracker_data.assign_attributes(
        url: 'A' * 3000,
        api_url: 'B' * 3000,
        username: 'C' * 3000,
        password: 'D' * 3000
      )

      jira_tracker_data.save!(validate: false)

      expect(jira_tracker_data.reload).to be_valid
    end
  end
end
