# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::IssueTrackerData, feature_category: :integrations do
  it_behaves_like Integrations::BaseDataFields

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:issues_url, :new_issue_url, :project_url) }
  end
end
