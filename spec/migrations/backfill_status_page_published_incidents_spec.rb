# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillStatusPagePublishedIncidents, :migration do
  subject(:migration) { described_class.new }

  describe '#up' do
    let(:projects) { table(:projects) }
    let(:status_page_settings) { table(:status_page_settings) }
    let(:issues) { table(:issues) }
    let(:incidents) { table(:status_page_published_incidents) }

    let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }
    let(:project_without_status_page) { projects.create!(namespace_id: namespace.id) }
    let(:enabled_project) { projects.create!(namespace_id: namespace.id) }
    let(:disabled_project) { projects.create!(namespace_id: namespace.id) }

    let!(:enabled_setting) { status_page_settings.create!(enabled: true, project_id: enabled_project.id, **status_page_setting_attrs) }
    let!(:disabled_setting) { status_page_settings.create!(enabled: false, project_id: disabled_project.id, **status_page_setting_attrs) }

    let!(:published_issue) { issues.create!(confidential: false, project_id: enabled_project.id) }
    let!(:nonpublished_issue_1) { issues.create!(confidential: true, project_id: enabled_project.id) }
    let!(:nonpublished_issue_2) { issues.create!(confidential: false, project_id: disabled_project.id) }
    let!(:nonpublished_issue_3) { issues.create!(confidential: false, project_id: project_without_status_page.id) }

    let(:current_time) { Time.current.change(usec: 0) }
    let(:status_page_setting_attrs) do
      {
        aws_s3_bucket_name: 'bucket',
        aws_region: 'region',
        aws_access_key: 'key',
        encrypted_aws_secret_key: 'abc123',
        encrypted_aws_secret_key_iv: 'abc123'
      }
    end

    it 'creates a StatusPage::PublishedIncident record for each published issue' do
      travel_to(current_time) do
        expect(incidents.all).to be_empty

        migrate!

        incident = incidents.first

        expect(incidents.count).to eq(1)
        expect(incident.issue_id).to eq(published_issue.id)
        expect(incident.created_at).to eq(current_time)
        expect(incident.updated_at).to eq(current_time)
      end
    end
  end
end
