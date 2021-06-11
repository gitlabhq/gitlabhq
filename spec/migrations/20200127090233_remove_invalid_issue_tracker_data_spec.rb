# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_invalid_issue_tracker_data')

RSpec.describe RemoveInvalidIssueTrackerData do
  let(:issue_tracker_data) { table(:issue_tracker_data) }
  let(:services) { table(:services) }

  let(:service) { services.create!(id: 1) }
  let(:data) do
    {
      service_id: service.id,
      encrypted_issues_url: 'http:url.com',
      encrypted_issues_url_iv: 'somevalue',
      encrypted_new_issue_url: 'http:url.com',
      encrypted_new_issue_url_iv: 'somevalue',
      encrypted_project_url: 'username',
      encrypted_project_url_iv: 'somevalue'
    }
  end

  let!(:valid_data) { issue_tracker_data.create!(data) }
  let!(:empty_data) { issue_tracker_data.create!(service_id: service.id) }
  let!(:invalid_issues_url) do
    data[:encrypted_issues_url_iv] = nil
    issue_tracker_data.create!(data)
  end

  let!(:missing_issues_url) do
    data[:encrypted_issues_url] = ''
    data[:encrypted_issues_url_iv] = nil
    issue_tracker_data.create!(data)
  end

  let!(:invalid_new_isue_url) do
    data[:encrypted_new_issue_url_iv] = nil
    issue_tracker_data.create!(data)
  end

  let!(:missing_new_issue_url) do
    data[:encrypted_new_issue_url] = ''
    issue_tracker_data.create!(data)
  end

  let!(:invalid_project_url) do
    data[:encrypted_project_url_iv] = nil
    issue_tracker_data.create!(data)
  end

  let!(:missing_project_url) do
    data[:encrypted_project_url] = nil
    data[:encrypted_project_url_iv] = nil
    issue_tracker_data.create!(data)
  end

  it 'removes the invalid data' do
    valid_data_records = [valid_data, empty_data, missing_issues_url, missing_new_issue_url, missing_project_url]

    expect { migrate! }.to change { issue_tracker_data.count }.from(8).to(5)

    expect(issue_tracker_data.all).to match_array(valid_data_records)
  end
end
