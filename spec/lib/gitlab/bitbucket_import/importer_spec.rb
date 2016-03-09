require 'spec_helper'

describe Gitlab::BitbucketImport::Importer, lib: true do
  before do
    Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "bitbucket")
  end

  let(:statuses) do
    [
      "open",
      "resolved",
      "on hold",
      "invalid",
      "duplicate",
      "wontfix",
      "closed"  # undocumented status
    ]
  end
  let(:sample_issues_statuses) do
    issues = []

    statuses.map.with_index do |status, index|
      issues << {
        local_id: index,
        status: status,
        title: "Issue #{index}",
        content: "Some content to issue #{index}"
      }
    end

    issues
  end

  let(:project_identifier) { 'namespace/repo' }
  let(:data) do
    {
      bb_session: {
        bitbucket_access_token: "123456",
        bitbucket_access_token_secret: "secret"
      }
    }
  end
  let(:project) do
    create(
      :project,
      import_source: project_identifier,
      import_data: ProjectImportData.new(data: data)
    )
  end
  let(:importer) { Gitlab::BitbucketImport::Importer.new(project) }
  let(:issues_statuses_sample_data) do
    {
      count: sample_issues_statuses.count,
      issues: sample_issues_statuses
    }
  end

  context 'issues statuses' do
    before do
      stub_request(
        :get,
        "https://bitbucket.org/api/1.0/repositories/#{project_identifier}"
      ).to_return(status: 200, body: { has_issues: true }.to_json)

      stub_request(
        :get,
        "https://bitbucket.org/api/1.0/repositories/#{project_identifier}/issues?limit=50&sort=utc_created_on&start=0"
      ).to_return(status: 200, body: issues_statuses_sample_data.to_json)

      sample_issues_statuses.each_with_index do |issue, index|
        stub_request(
          :get,
          "https://bitbucket.org/api/1.0/repositories/#{project_identifier}/issues/#{issue[:local_id]}/comments"
        ).to_return(
          status: 200,
          body: [{ author_info: { username: "username" }, utc_created_on: index }].to_json
        )
      end
    end

    it 'map statuses to open or closed' do
      importer.execute

      expect(project.issues.where(state: "closed").size).to eq(5)
      expect(project.issues.where(state: "opened").size).to eq(2)
    end
  end
end
