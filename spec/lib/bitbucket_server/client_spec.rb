# frozen_string_literal: true

require 'spec_helper'

describe BitbucketServer::Client do
  let(:base_uri) { 'https://test:7990/stash/' }
  let(:options) { { base_uri: base_uri, user: 'bitbucket', password: 'mypassword' } }
  let(:project) { 'SOME-PROJECT' }
  let(:repo_slug) { 'my-repo' }
  let(:headers) { { "Content-Type" => "application/json" } }

  subject { described_class.new(options) }

  describe '#pull_requests' do
    let(:path) { "/projects/#{project}/repos/#{repo_slug}/pull-requests?state=ALL" }

    it 'requests a collection' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :pull_request, page_offset: 0, limit: nil)

      subject.pull_requests(project, repo_slug)
    end
  end

  describe '#activities' do
    let(:path) { "/projects/#{project}/repos/#{repo_slug}/pull-requests/1/activities" }

    it 'requests a collection' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :activity, page_offset: 0, limit: nil)

      subject.activities(project, repo_slug, 1)
    end
  end

  describe '#repo' do
    let(:path) { "/projects/#{project}/repos/#{repo_slug}" }
    let(:url) { "#{base_uri}rest/api/1.0/projects/SOME-PROJECT/repos/my-repo" }

    it 'requests a specific repository' do
      stub_request(:get, url).to_return(status: 200, headers: headers, body: '{}')

      subject.repo(project, repo_slug)

      expect(WebMock).to have_requested(:get, url)
    end
  end

  describe '#repos' do
    let(:path) { "/repos" }

    it 'requests a collection' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :repo, page_offset: 0, limit: nil)

      subject.repos
    end

    it 'requests a collection with an offset and limit' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :repo, page_offset: 10, limit: 25)

      subject.repos(page_offset: 10, limit: 25)
    end
  end

  describe '#create_branch' do
    let(:branch) { 'test-branch' }
    let(:sha) { '12345678' }
    let(:url) { "#{base_uri}rest/api/1.0/projects/SOME-PROJECT/repos/my-repo/branches" }

    it 'requests Bitbucket to create a branch' do
      stub_request(:post, url).to_return(status: 204, headers: headers, body: nil)

      subject.create_branch(project, repo_slug, branch, sha)

      expect(WebMock).to have_requested(:post, url)
    end
  end

  describe '#delete_branch' do
    let(:branch) { 'test-branch' }
    let(:sha) { '12345678' }
    let(:url) { "#{base_uri}rest/branch-utils/1.0/projects/SOME-PROJECT/repos/my-repo/branches" }

    it 'requests Bitbucket to create a branch' do
      stub_request(:delete, url).to_return(status: 204, headers: headers, body: nil)

      subject.delete_branch(project, repo_slug, branch, sha)

      expect(WebMock).to have_requested(:delete, url)
    end
  end
end
