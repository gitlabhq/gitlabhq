# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestsImporter do
  let(:url) { 'https://github.com/foo/bar.git' }
  let(:project) { create(:project, import_source: 'foo/bar', import_url: url) }
  let(:client) { double(:client) }

  let(:pull_request) do
    double(
      :response,
      number: 42,
      title: 'My Pull Request',
      body: 'This is my pull request',
      state: 'closed',
      head: double(
        :head,
        sha: '123abc',
        ref: 'my-feature',
        repo: double(:repo, id: 400),
        user: double(:user, id: 4, login: 'alice')
      ),
      base: double(
        :base,
        sha: '456def',
        ref: 'master',
        repo: double(:repo, id: 200)
      ),
      milestone: double(:milestone, number: 4),
      user: double(:user, id: 4, login: 'alice'),
      assignee: double(:user, id: 4, login: 'alice'),
      merged_by: double(:user, id: 4, login: 'alice'),
      created_at: 1.second.ago,
      updated_at: 1.second.ago,
      merged_at: 1.second.ago
    )
  end

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      importer = described_class.new(project, client)
      expect(importer).to be_parallel
    end

    it 'returns false when running in sequential mode' do
      importer = described_class.new(project, client, parallel: false)
      expect(importer).not_to be_parallel
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports pull requests in parallel' do
        importer = described_class.new(project, client)

        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      it 'imports pull requests in sequence' do
        importer = described_class.new(project, client, parallel: false)

        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    it 'imports each pull request in sequence' do
      importer = described_class.new(project, client, parallel: false)
      pull_request_importer = double(:pull_request_importer)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(pull_request)

      expect(Gitlab::GithubImport::Importer::PullRequestImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::PullRequest),
          project,
          client
        )
        .and_return(pull_request_importer)

      expect(pull_request_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import' do
    it 'imports each note in parallel' do
      importer = described_class.new(project, client)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(pull_request)

      expect(Gitlab::GithubImport::ImportPullRequestWorker)
        .to receive(:perform_async)
        .with(project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let(:importer) { described_class.new(project, client) }

    before do
      page = double(:page, objects: [pull_request], number: 1)

      expect(client)
        .to receive(:each_page)
        .with(
          :pull_requests,
          'foo/bar',
          { state: 'all', sort: 'created', direction: 'asc', page: 1 }
        )
        .and_yield(page)
    end

    it 'yields every pull request to the supplied block' do
      expect { |b| importer.each_object_to_import(&b) }
        .to yield_with_args(pull_request)
    end

    it 'updates the repository if a pull request was updated after the last clone' do
      expect(importer)
        .to receive(:update_repository?)
        .with(pull_request)
        .and_return(true)

      expect(importer)
        .to receive(:update_repository)

      importer.each_object_to_import { }
    end
  end

  shared_examples '#update_repository' do
    it 'updates the repository' do
      importer = described_class.new(project, client)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(an_instance_of(Hash))
      end

      expect(importer.repository_updates_counter)
        .to receive(:increment)
        .and_call_original

      freeze_time do
        importer.update_repository

        expect(project.last_repository_updated_at).to be_like_time(Time.zone.now)
      end
    end
  end

  describe '#update_repository with :fetch_remote_params enabled' do
    before do
      stub_feature_flags(fetch_remote_params: true)
      expect(project.repository)
        .to receive(:fetch_remote)
        .with('github', forced: false, url: url, refmap: Gitlab::GithubImport.refmap)
    end

    it_behaves_like '#update_repository'
  end

  describe '#update_repository with :fetch_remote_params disabled' do
    before do
      stub_feature_flags(fetch_remote_params: false)
      expect(project.repository)
        .to receive(:fetch_remote)
        .with('github', forced: false)
    end

    it_behaves_like '#update_repository'
  end

  describe '#update_repository?' do
    let(:importer) { described_class.new(project, client) }

    context 'when the pull request was updated after the last update' do
      let(:pr) do
        double(
          :pr,
          updated_at: Time.zone.now,
          head: double(:head, sha: '123'),
          base: double(:base, sha: '456')
        )
      end

      before do
        allow(project)
          .to receive(:last_repository_updated_at)
          .and_return(1.year.ago)
      end

      it 'returns true when the head SHA is not present' do
        expect(importer)
          .to receive(:commit_exists?)
          .with(pr.head.sha)
          .and_return(false)

        expect(importer.update_repository?(pr)).to eq(true)
      end

      it 'returns true when the base SHA is not present' do
        expect(importer)
          .to receive(:commit_exists?)
          .with(pr.head.sha)
          .and_return(true)

        expect(importer)
          .to receive(:commit_exists?)
          .with(pr.base.sha)
          .and_return(false)

        expect(importer.update_repository?(pr)).to eq(true)
      end

      it 'returns false if both the head and base SHAs are present' do
        expect(importer)
          .to receive(:commit_exists?)
          .with(pr.head.sha)
          .and_return(true)

        expect(importer)
          .to receive(:commit_exists?)
          .with(pr.base.sha)
          .and_return(true)

        expect(importer.update_repository?(pr)).to eq(false)
      end
    end

    context 'when the pull request was updated before the last update' do
      it 'returns false' do
        pr = double(:pr, updated_at: 1.year.ago)

        allow(project)
          .to receive(:last_repository_updated_at)
          .and_return(Time.zone.now)

        expect(importer.update_repository?(pr)).to eq(false)
      end
    end
  end

  describe '#commit_exists?' do
    let(:importer) { described_class.new(project, client) }

    it 'returns true when a commit exists' do
      expect(project.repository)
        .to receive(:commit)
        .with('123')
        .and_return(double(:commit))

      expect(importer.commit_exists?('123')).to eq(true)
    end

    it 'returns false when a commit does not exist' do
      expect(project.repository)
        .to receive(:commit)
        .with('123')
        .and_return(nil)

      expect(importer.commit_exists?('123')).to eq(false)
    end
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the PR number of the given PR' do
      importer = described_class.new(project, client)

      expect(importer.id_for_already_imported_cache(pull_request))
        .to eq(42)
    end
  end
end
