require 'spec_helper'

describe Gitlab::BitbucketImport::Importer do
  include ImportSpecHelper

  before do
    stub_omniauth_provider('bitbucket')
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
        id: index,
        state: status,
        title: "Issue #{index}",
        kind: 'bug',
        content: {
            raw: "Some content to issue #{index}",
            markup: "markdown",
            html: "Some content to issue #{index}"
        }
      }
    end

    issues
  end

  let(:project_identifier) { 'namespace/repo' }

  let(:data) do
    {
      'bb_session' => {
        'bitbucket_token' => "123456",
        'bitbucket_refresh_token' => "secret"
      }
    }
  end

  let(:project) do
    create(
      :empty_project,
      import_source: project_identifier,
      import_data: ProjectImportData.new(credentials: data)
    )
  end

  let(:importer) { described_class.new(project) }

  let(:issues_statuses_sample_data) do
    {
      count: sample_issues_statuses.count,
      values: sample_issues_statuses
    }
  end

  context 'issues statuses' do
    before do
      # HACK: Bitbucket::Representation.const_get('Issue') seems to return ::Issue without this
      Bitbucket::Representation::Issue.new({})

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: { has_issues: true, full_name: project_identifier }.to_json)

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/issues?pagelen=50&sort=created_on"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: issues_statuses_sample_data.to_json)

      stub_request(:get, "https://api.bitbucket.org/2.0/repositories/namespace/repo?pagelen=50&sort=created_on")
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'Bearer', 'User-Agent' => 'Faraday v0.9.2' })
        .to_return(status: 200, body: "", headers: {})

      sample_issues_statuses.each_with_index do |issue, index|
        stub_request(
          :get,
          "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/issues/#{issue[:id]}/comments?pagelen=50&sort=created_on"
        ).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: { author_info: { username: "username" }, utc_created_on: index }.to_json
        )
      end

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/pullrequests?pagelen=50&sort=created_on&state=ALL"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: {}.to_json)
    end

    it 'maps statuses to open or closed' do
      importer.execute

      expect(project.issues.where(state: "closed").size).to eq(5)
      expect(project.issues.where(state: "opened").size).to eq(2)
    end

    it 'calls import_wiki' do
      expect(importer).to receive(:import_wiki)
      importer.execute
    end
  end
end
