# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_invalid_jira_data')

RSpec.describe RemoveInvalidJiraData do
  let(:jira_tracker_data) { table(:jira_tracker_data) }
  let(:services) { table(:services) }

  let(:service) { services.create!(id: 1) }
  let(:data) do
    {
      service_id: service.id,
      encrypted_api_url: 'http:url.com',
      encrypted_api_url_iv: 'somevalue',
      encrypted_url: 'http:url.com',
      encrypted_url_iv: 'somevalue',
      encrypted_username: 'username',
      encrypted_username_iv: 'somevalue',
      encrypted_password: 'username',
      encrypted_password_iv: 'somevalue'
    }
  end

  let!(:valid_data) { jira_tracker_data.create!(data) }
  let!(:empty_data) { jira_tracker_data.create!(service_id: service.id) }
  let!(:invalid_api_url) do
    data[:encrypted_api_url_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:missing_api_url) do
    data[:encrypted_api_url] = ''
    data[:encrypted_api_url_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:invalid_url) do
    data[:encrypted_url_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:missing_url) do
    data[:encrypted_url] = ''
    jira_tracker_data.create!(data)
  end

  let!(:invalid_username) do
    data[:encrypted_username_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:missing_username) do
    data[:encrypted_username] = nil
    data[:encrypted_username_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:invalid_password) do
    data[:encrypted_password_iv] = nil
    jira_tracker_data.create!(data)
  end

  let!(:missing_password) do
    data[:encrypted_password] = nil
    data[:encrypted_username_iv] = nil
    jira_tracker_data.create!(data)
  end

  it 'removes the invalid data' do
    valid_data_records = [valid_data, empty_data, missing_api_url, missing_url, missing_username, missing_password]

    expect { migrate! }.to change { jira_tracker_data.count }.from(10).to(6)

    expect(jira_tracker_data.all).to match_array(valid_data_records)
  end
end
