# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Client, feature_category: :importers do
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

    it 'requests a collection with offset and limit' do
      offset = 10
      limit = 100

      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :pull_request, page_offset: offset, limit: limit)

      subject.pull_requests(project, repo_slug, page_offset: offset, limit: limit)
    end
  end

  describe '#last_pull_request' do
    let(:path) { "/projects/#{project}/repos/#{repo_slug}/pull-requests?state=ALL&order=NEWEST" }

    it 'requests a collection with the default page length' do
      expect(BitbucketServer::Paginator).to receive(:new)
        .with(anything, path, :pull_request, page_offset: 0, limit: BitbucketServer::Paginator::PAGE_LENGTH)
        .and_return(instance_double(BitbucketServer::Paginator))

      collection = instance_double(BitbucketServer::Collection)
      allow(BitbucketServer::Collection).to receive(:new).and_return(collection)
      allow(collection).to receive(:max_by).and_return(nil)

      subject.last_pull_request(project, repo_slug)
    end

    it 'returns the pull request with the highest iid' do
      pr_1 = instance_double(BitbucketServer::Representation::PullRequest, iid: 100)
      pr_2 = instance_double(BitbucketServer::Representation::PullRequest, iid: 102)
      pr_3 = instance_double(BitbucketServer::Representation::PullRequest, iid: 101)
      collection = instance_double(BitbucketServer::Collection)
      allow(collection).to receive(:max_by).and_yield(pr_1).and_yield(pr_2).and_yield(pr_3).and_return(pr_2)

      allow(BitbucketServer::Collection).to receive(:new).and_return(collection)

      expect(subject.last_pull_request(project, repo_slug)).to eq(pr_2)
    end

    it 'returns nil when there are no pull requests' do
      collection = instance_double(BitbucketServer::Collection)
      allow(collection).to receive(:max_by).and_return(nil)

      allow(BitbucketServer::Collection).to receive(:new).and_return(collection)

      expect(subject.last_pull_request(project, repo_slug)).to be_nil
    end
  end

  describe '#activities' do
    let(:path) { "/projects/#{project}/repos/#{repo_slug}/pull-requests/1/activities" }

    it 'requests a collection' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :activity, page_offset: 0, limit: nil)

      subject.activities(project, repo_slug, 1)
    end

    it 'requests a collection with offset and limit' do
      offset = 10
      limit = 100

      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :activity, page_offset: offset, limit: limit)

      subject.activities(project, repo_slug, 1, page_offset: offset, limit: limit)
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

    context 'when filter param is passed' do
      let(:filter) { 'test' }
      let(:expected_path) { "#{path}?name=#{filter}" }

      it 'requests a collection with filter applied' do
        expect(BitbucketServer::Paginator).to receive(:new).with(anything, expected_path, :repo, page_offset: 0, limit: nil)

        subject.repos(filter: filter)
      end
    end
  end

  describe '#users' do
    let(:path) { "/projects/#{project}/permissions/users" }

    it 'requests a collection' do
      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :user, page_offset: 0, limit: nil)

      subject.users(project)
    end

    it 'requests a collection with offset and limit' do
      offset = 10
      limit = 100

      expect(BitbucketServer::Paginator).to receive(:new).with(anything, path, :user, page_offset: offset, limit: limit)

      subject.users(project, page_offset: offset, limit: limit)
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
