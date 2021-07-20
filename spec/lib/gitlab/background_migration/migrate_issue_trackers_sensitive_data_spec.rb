# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateIssueTrackersSensitiveData, schema: 20200130145430 do
  let(:services) { table(:services) }

  before do
    # we need to define the classes due to encryption
    issue_tracker_data = Class.new(ApplicationRecord) do
      self.table_name = 'issue_tracker_data'

      def self.encryption_options
        {
          key: Settings.attr_encrypted_db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end

      attr_encrypted :project_url, encryption_options
      attr_encrypted :issues_url, encryption_options
      attr_encrypted :new_issue_url, encryption_options
    end

    jira_tracker_data = Class.new(ApplicationRecord) do
      self.table_name = 'jira_tracker_data'

      def self.encryption_options
        {
          key: Settings.attr_encrypted_db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end

      attr_encrypted :url, encryption_options
      attr_encrypted :api_url, encryption_options
      attr_encrypted :username, encryption_options
      attr_encrypted :password, encryption_options
    end

    stub_const('IssueTrackerData', issue_tracker_data)
    stub_const('JiraTrackerData', jira_tracker_data)
  end

  let(:url) { 'http://base-url.tracker.com' }
  let(:new_issue_url) { 'http://base-url.tracker.com/new_issue' }
  let(:issues_url) { 'http://base-url.tracker.com/issues' }
  let(:api_url) { 'http://api.tracker.com' }
  let(:password) { 'passw1234' }
  let(:username) { 'user9' }
  let(:title) { 'Issue tracker' }
  let(:description) { 'Issue tracker description' }

  let(:jira_properties) do
    {
      'api_url' => api_url,
      'jira_issue_transition_id' => '5',
      'password' => password,
      'url' => url,
      'username' => username,
      'title' => title,
      'description' => description,
      'other_field' => 'something'
    }
  end

  let(:tracker_properties) do
    {
      'project_url' => url,
      'new_issue_url' => new_issue_url,
      'issues_url' => issues_url,
      'title' => title,
      'description' => description,
      'other_field' => 'something'
    }
  end

  let(:tracker_properties_no_url) do
    {
      'new_issue_url' => new_issue_url,
      'issues_url' => issues_url,
      'title' => title,
      'description' => description
    }
  end

  subject { described_class.new.perform(1, 100) }

  shared_examples 'handle properties' do
    it 'does not clear the properties' do
      expect { subject }.not_to change { service.reload.properties}
    end
  end

  context 'with Jira service' do
    let!(:service) do
      services.create!(id: 10, type: 'JiraService', title: nil, properties: jira_properties.to_json, category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'migrates data' do
      expect { subject }.to change { JiraTrackerData.count }.by(1)

      service.reload
      data = JiraTrackerData.find_by(service_id: service.id)

      expect(data.url).to eq(url)
      expect(data.api_url).to eq(api_url)
      expect(data.username).to eq(username)
      expect(data.password).to eq(password)
      expect(service.title).to eq(title)
      expect(service.description).to eq(description)
    end
  end

  context 'with bugzilla service' do
    let!(:service) do
      services.create!(id: 11, type: 'BugzillaService', title: nil, properties: tracker_properties.to_json, category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'migrates data' do
      expect { subject }.to change { IssueTrackerData.count }.by(1)

      service.reload
      data = IssueTrackerData.find_by(service_id: service.id)

      expect(data.project_url).to eq(url)
      expect(data.issues_url).to eq(issues_url)
      expect(data.new_issue_url).to eq(new_issue_url)
      expect(service.title).to eq(title)
      expect(service.description).to eq(description)
    end
  end

  context 'with youtrack service' do
    let!(:service) do
      services.create!(id: 12, type: 'YoutrackService', title: nil, properties: tracker_properties_no_url.to_json, category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'migrates data' do
      expect { subject }.to change { IssueTrackerData.count }.by(1)

      service.reload
      data = IssueTrackerData.find_by(service_id: service.id)

      expect(data.project_url).to be_nil
      expect(data.issues_url).to eq(issues_url)
      expect(data.new_issue_url).to eq(new_issue_url)
      expect(service.title).to eq(title)
      expect(service.description).to eq(description)
    end
  end

  context 'with gitlab service with no properties' do
    let!(:service) do
      services.create!(id: 13, type: 'GitlabIssueTrackerService', title: nil, properties: {}, category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'does not migrate data' do
      expect { subject }.not_to change { IssueTrackerData.count }
    end
  end

  context 'with redmine service already with data fields' do
    let!(:service) do
      services.create!(id: 14, type: 'RedmineService', title: nil, properties: tracker_properties_no_url.to_json, category: 'issue_tracker').tap do |service|
        IssueTrackerData.create!(service_id: service.id, project_url: url, new_issue_url: new_issue_url, issues_url: issues_url)
      end
    end

    it_behaves_like 'handle properties'

    it 'does not create new data fields record' do
      expect { subject }.not_to change { IssueTrackerData.count }
    end
  end

  context 'with custom issue tracker which has data fields record inconsistent with properties field' do
    let!(:service) do
      services.create!(id: 15, type: 'CustomIssueTrackerService', title: 'Existing title', properties: jira_properties.to_json, category: 'issue_tracker').tap do |service|
        IssueTrackerData.create!(service_id: service.id, project_url: 'http://other_url', new_issue_url: 'http://other_url/new_issue', issues_url: 'http://other_url/issues')
      end
    end

    it_behaves_like 'handle properties'

    it 'does not update the data fields record' do
      expect { subject }.not_to change { IssueTrackerData.count }

      service.reload
      data = IssueTrackerData.find_by(service_id: service.id)

      expect(data.project_url).to eq('http://other_url')
      expect(data.issues_url).to eq('http://other_url/issues')
      expect(data.new_issue_url).to eq('http://other_url/new_issue')
      expect(service.title).to eq('Existing title')
    end
  end

  context 'with Jira service which has data fields record inconsistent with properties field' do
    let!(:service) do
      services.create!(id: 16, type: 'CustomIssueTrackerService', description: 'Existing description', properties: jira_properties.to_json, category: 'issue_tracker').tap do |service|
        JiraTrackerData.create!(service_id: service.id, url: 'http://other_jira_url')
      end
    end

    it_behaves_like 'handle properties'

    it 'does not update the data fields record' do
      expect { subject }.not_to change { JiraTrackerData.count }

      service.reload
      data = JiraTrackerData.find_by(service_id: service.id)

      expect(data.url).to eq('http://other_jira_url')
      expect(data.password).to be_nil
      expect(data.username).to be_nil
      expect(data.api_url).to be_nil
      expect(service.description).to eq('Existing description')
    end
  end

  context 'non issue tracker service' do
    let!(:service) do
      services.create!(id: 17, title: nil, description: nil, type: 'OtherService', properties: tracker_properties.to_json)
    end

    it_behaves_like 'handle properties'

    it 'does not migrate any data' do
      expect { subject }.not_to change { IssueTrackerData.count }

      service.reload
      expect(service.title).to be_nil
      expect(service.description).to be_nil
    end
  end

  context 'Jira service with empty properties' do
    let!(:service) do
      services.create!(id: 18, type: 'JiraService', properties: '', category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'does not migrate any data' do
      expect { subject }.not_to change { JiraTrackerData.count }
    end
  end

  context 'Jira service with nil properties' do
    let!(:service) do
      services.create!(id: 18, type: 'JiraService', properties: nil, category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'does not migrate any data' do
      expect { subject }.not_to change { JiraTrackerData.count }
    end
  end

  context 'Jira service with invalid properties' do
    let!(:service) do
      services.create!(id: 18, type: 'JiraService', properties: 'invalid data', category: 'issue_tracker')
    end

    it_behaves_like 'handle properties'

    it 'does not migrate any data' do
      expect { subject }.not_to change { JiraTrackerData.count }
    end
  end

  context 'with Jira service with invalid properties, valid Jira service and valid bugzilla service' do
    let!(:jira_integration_invalid) do
      services.create!(id: 19, title: 'invalid - title', description: 'invalid - description', type: 'JiraService', properties: 'invalid data', category: 'issue_tracker')
    end

    let!(:jira_integration_valid) do
      services.create!(id: 20, type: 'JiraService', properties: jira_properties.to_json, category: 'issue_tracker')
    end

    let!(:bugzilla_integration_valid) do
      services.create!(id: 11, type: 'BugzillaService', title: nil, properties: tracker_properties.to_json, category: 'issue_tracker')
    end

    it 'migrates data for the valid service' do
      subject

      jira_integration_invalid.reload
      expect(JiraTrackerData.find_by(service_id: jira_integration_invalid.id)).to be_nil
      expect(jira_integration_invalid.title).to eq('invalid - title')
      expect(jira_integration_invalid.description).to eq('invalid - description')
      expect(jira_integration_invalid.properties).to eq('invalid data')

      jira_integration_valid.reload
      data = JiraTrackerData.find_by(service_id: jira_integration_valid.id)

      expect(data.url).to eq(url)
      expect(data.api_url).to eq(api_url)
      expect(data.username).to eq(username)
      expect(data.password).to eq(password)
      expect(jira_integration_valid.title).to eq(title)
      expect(jira_integration_valid.description).to eq(description)

      bugzilla_integration_valid.reload
      data = IssueTrackerData.find_by(service_id: bugzilla_integration_valid.id)

      expect(data.project_url).to eq(url)
      expect(data.issues_url).to eq(issues_url)
      expect(data.new_issue_url).to eq(new_issue_url)
      expect(bugzilla_integration_valid.title).to eq(title)
      expect(bugzilla_integration_valid.description).to eq(description)
    end
  end
end
