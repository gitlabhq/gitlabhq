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
      :project,
      import_source: project_identifier,
      import_url: "https://bitbucket.org/#{project_identifier}.git",
      import_data_attributes: { credentials: data }
    )
  end

  let(:importer) { described_class.new(project) }
  let(:gitlab_shell) { double }

  let(:issues_statuses_sample_data) do
    {
      count: sample_issues_statuses.count,
      values: sample_issues_statuses
    }
  end

  before do
    allow(importer).to receive(:gitlab_shell) { gitlab_shell }
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
      allow(importer).to receive(:import_wiki)

      importer.execute

      expect(project.issues.where(state: "closed").size).to eq(5)
      expect(project.issues.where(state: "opened").size).to eq(2)
    end

    describe 'wiki import' do
      it 'is skipped when the wiki exists' do
        expect(project.wiki).to receive(:repository_exists?) { true }
        expect(importer.gitlab_shell).not_to receive(:import_repository)

        importer.execute

        expect(importer.errors).to be_empty
      end

      it 'imports to the project disk_path' do
        expect(project.wiki).to receive(:repository_exists?) { false }
        expect(importer.gitlab_shell).to receive(:import_repository).with(
          project.repository_storage_path,
          project.wiki.disk_path,
          project.import_url + '/wiki'
        )

        importer.execute

        expect(importer.errors).to be_empty
      end
    end
  end
end
