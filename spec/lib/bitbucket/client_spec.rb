# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::Client, feature_category: :importers do
  let(:base_uri) { 'https://api.bitbucket.org/' }
  let(:api_version) { '2.0' }
  let(:root_url) { "#{base_uri}#{api_version}" }
  let(:workspace) { 'my-workspace' }
  let(:repo) { 'my-workspace/my-repo' }
  let(:options) { { token: 'someToken', base_uri: base_uri, api_version: api_version } }
  let(:headers) { { "Content-Type" => "application/json" } }

  subject(:client) { described_class.new(options) }

  describe '#last_issue' do
    let(:url) { "#{root_url}/repositories/#{repo}/issues?pagelen=1&sort=-created_on&state=ALL" }

    it 'requests one issue' do
      stub_request(:get, url).to_return(
        status: 200,
        headers: headers,
        body: { 'values' => [{ 'kind' => 'bug' }] }.to_json
      )

      client.last_issue(repo)

      expect(WebMock).to have_requested(:get, url)
    end
  end

  describe '#issues' do
    let(:path) { "/repositories/#{repo}/issues?sort=created_on" }

    it 'requests a collection' do
      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :issue, page_number: nil, limit: nil)

      client.issues(repo)
    end
  end

  describe '#issue_comments' do
    let(:issue_id) { 3 }
    let(:path) { "/repositories/#{repo}/issues/#{issue_id}/comments?sort=created_on" }

    it 'requests a collection' do
      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :comment, page_number: nil, limit: nil)

      client.issue_comments(repo, issue_id)
    end
  end

  describe '#pull_requests' do
    let(:path) { "/repositories/#{repo}/pullrequests?state=ALL&sort=created_on" }

    it 'requests a collection' do
      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :pull_request, page_number: nil, limit: nil)

      client.pull_requests(repo)
    end
  end

  describe '#pull_request_comments' do
    let(:pull_request_id) { 5 }
    let(:path) { "/repositories/#{repo}/pullrequests/#{pull_request_id}/comments?sort=created_on" }

    it 'requests a collection' do
      expect(Bitbucket::Paginator).to receive(:new).with(
        anything, path, :pull_request_comment, page_number: nil, limit: nil
      )

      client.pull_request_comments(repo, pull_request_id)
    end
  end

  describe '#pull_request_diff' do
    let(:pull_request_id) { 5 }
    let(:url) { "#{root_url}/repositories/#{repo}/pullrequests/#{pull_request_id}/diff" }

    it 'requests the diff on a pull request' do
      stub_request(:get, url).to_return(status: 200, headers: headers, body: '{}')

      client.pull_request_diff(repo, pull_request_id)

      expect(WebMock).to have_requested(:get, url)
    end
  end

  describe '#repo' do
    let(:url) { "#{root_url}/repositories/#{repo}" }

    it 'requests a specific repository' do
      stub_request(:get, url).to_return(status: 200, headers: headers, body: '{}')

      client.repo(repo)

      expect(WebMock).to have_requested(:get, url)
    end
  end

  describe '#repos' do
    let(:path) { "/repositories?role=member&sort=created_on" }
    let(:repo_name_filter) { 'my' }

    it 'requests a collection without a filter' do
      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :repo, page_number: nil, limit: nil)

      client.repos
    end

    it 'requests a collection with a filter' do
      path_with_filter = "#{path}&q=name~\"#{repo_name_filter}\""

      expect(Bitbucket::Paginator).to receive(:new).with(
        anything, path_with_filter, :repo, page_number: nil, limit: nil
      )

      client.repos(filter: repo_name_filter)
    end
  end

  describe '#user' do
    let(:url) { "#{root_url}/user" }

    it 'requests the current user once per instance' do
      stub_request(:get, url).to_return(status: 200, headers: headers, body: '{}')

      client.user
      client.user

      expect(WebMock).to have_requested(:get, url).once
    end
  end

  describe '#users' do
    let(:path) { "/workspaces/#{workspace}/members" }

    it 'requests a collection' do
      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :user, page_number: nil, limit: nil)

      client.users(workspace)
    end

    it 'requests a collection with page offset and limit' do
      page = 10
      limit = 100

      expect(Bitbucket::Paginator).to receive(:new).with(anything, path, :user, page_number: page, limit: limit)

      client.users(workspace, page_number: page, limit: limit)
    end
  end
end
