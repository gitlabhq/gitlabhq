# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::Importer, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::GiteaHelper

  subject(:importer) { described_class.new(project) }

  let_it_be(:api_root) { 'https://try.gitea.io/api/v1' }
  let_it_be(:repo_root) { 'https://try.gitea.io' }
  let_it_be(:project) do
    create(
      :project, :repository, :wiki_disabled, :import_user_mapping_enabled,
      import_url: "#{repo_root}/foo/group/project.git",
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let(:credentials) { { user: 'joe' } }
  let(:store) { project.placeholder_reference_store }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:repository) { { id: 1, fork: false } }
  let(:source_sha) { create(:commit, project: project).id }
  let(:source_branch) { { ref: 'branch-merged', repo: repository, sha: source_sha, user: octocat } }
  let(:target_sha) { create(:commit, project: project, git_commit: RepoHelpers.another_sample_commit).id }
  let(:target_branch) { { ref: 'master', repo: repository, sha: target_sha, user: octocat } }
  let(:pull_request) do
    {
      number: 1347,
      milestone: nil,
      state: 'open',
      title: 'New feature',
      body: 'Please pull these awesome changes',
      head: source_branch,
      base: target_branch,
      assignee: nil,
      user: octocat,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil,
      merged_at: nil,
      url: "#{api_root}/repos/octocat/Hello-World/pulls/1347",
      labels: [{ name: 'Label #2' }]
    }
  end

  let(:pull_request_missing_source_branch) do
    pull_request.merge(
      head: {
        ref: 'missing',
        repo: repository,
        sha: RepoHelpers.another_sample_commit
      }
    )
  end

  let(:closed_pull_request) do
    {
      number: 1347,
      milestone: nil,
      state: 'closed',
      title: 'New feature',
      body: 'Please pull these awesome changes',
      head: source_branch,
      base: target_branch,
      assignee: nil,
      user: octocat,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: updated_at,
      merged_at: nil,
      url: "#{api_root}/repos/octocat/Hello-World/pulls/1347",
      labels: [{ name: 'Label #2' }]
    }
  end

  let(:label1) do
    {
      name: 'Bug',
      color: 'ff0000',
      url: "#{api_root}/repos/octocat/Hello-World/labels/bug"
    }
  end

  let(:label2) do
    {
      name: nil,
      color: 'ff0000',
      url: "#{api_root}/repos/octocat/Hello-World/labels/bug"
    }
  end

  let(:milestone) do
    {
      id: 1347, # For Gitea
      number: 1347,
      state: 'open',
      title: '1.0',
      description: 'Version 1.0',
      due_on: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil,
      url: "#{api_root}/repos/octocat/Hello-World/milestones/1"
    }
  end

  let(:issue1) do
    {
      number: 1347,
      milestone: nil,
      state: 'open',
      title: 'Found a bug',
      body: "I'm having a problem with this.",
      assignee: nil,
      user: octocat,
      comments: 0,
      pull_request: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil,
      url: "#{api_root}/repos/octocat/Hello-World/issues/1347",
      labels: [{ name: 'Label #1' }]
    }
  end

  let(:issue2) do
    {
      number: 1348,
      milestone: nil,
      state: 'open',
      title: nil,
      body: "I'm having a problem with this.",
      assignee: nil,
      user: octocat,
      comments: 0,
      pull_request: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil,
      url: "#{api_root}/repos/octocat/Hello-World/issues/1348",
      labels: [{ name: 'Label #2' }]
    }
  end

  let(:release1) do
    {
      tag_name: 'v1.0.0',
      name: 'First release',
      body: 'Release v1.0.0',
      draft: false,
      created_at: created_at,
      published_at: created_at,
      updated_at: updated_at,
      url: "#{api_root}/repos/octocat/Hello-World/releases/1"
    }
  end

  let(:release2) do
    {
      tag_name: 'v1.1.0',
      name: 'Second release',
      body: nil,
      draft: false,
      created_at: created_at,
      published_at: created_at,
      updated_at: updated_at,
      url: "#{api_root}/repos/octocat/Hello-World/releases/2"
    }
  end

  describe '#execute' do
    before do
      allow(Import::PlaceholderReferences::Store).to receive(:new).and_return(store)
      allow(store).to receive(:empty?).and_return(true)

      # Lower wait and timeout limit to make spec faster
      stub_const("#{described_class}::PLACEHOLDER_LOAD_SLEEP", 0.01)
      stub_const("#{described_class}::PLACEHOLDER_LOAD_TIMEOUT", 0.05)
    end

    context 'with stages' do
      before do
        allow(project).to receive(:import_data).and_return(double.as_null_object)
        allow(project).to receive_message_chain(:wiki, :repository_exists?).and_return(true)
        allow(importer).to receive(:fetch_resources).and_return(nil)
      end

      it 'calls gitea importer stages', :aggregate_failures do
        expect(importer).to receive(:import_labels).and_call_original
        expect(importer).to receive(:import_milestones).and_call_original
        expect(importer).to receive(:import_pull_requests).and_call_original
        expect(importer).to receive(:import_issues).and_call_original
        expect(importer).to receive(:import_wiki).and_call_original
        expect(importer).to receive(:handle_errors).and_call_original
        expect(importer).to receive(:import_comments).with(:issues).and_call_original

        importer.execute
      end

      it 'does not call github-specific importer stages', :aggregate_failures do
        expect(importer).not_to receive(:import_releases)
        expect(importer).not_to receive(:import_comments).with(:pull_requests)

        importer.execute
      end

      it 'loads placeholder references after each relevant stage' do
        # import_wiki does not load placeholder references because it doesn't have any user attributes to map
        # handle_errors does not create GitLab records
        stages_that_push_placeholder_references = [
          :import_pull_requests, :import_issues, :import_comments
        ]

        expect(::Import::LoadPlaceholderReferencesWorker).to receive(:perform_async).exactly(
          stages_that_push_placeholder_references.length
        ).times.with(
          project.import_type,
          project.import_state.id,
          'current_user_id' => project.creator_id
        )

        importer.execute
      end

      it 'waits for the placeholder references to be loaded from the store without error' do
        allow(store).to receive(:empty?).and_return(false, false, false, false, true)

        expect(Kernel).to receive(:sleep).with(0.01).exactly(4).times

        importer.execute

        expect(Gitlab::Json.parse(project.import_state.last_error)).to be_nil
      end

      it 'times out and logs an error when references fail to load' do
        allow(store).to receive(:empty?).and_return(false)

        expect(Kernel).to receive(:sleep).with(0.01).exactly(5).times

        importer.execute

        expect(Gitlab::Json.parse(project.import_state.last_error)).to include({
          'errors' => include(
            {
              'type' => 'placeholder_references',
              'errors' => "Timed out after waiting #{described_class::PLACEHOLDER_LOAD_TIMEOUT} seconds " \
                "for placeholder references to finish saving"
            }
          )
        })
      end

      context 'when user contribution mapping is disabled' do
        before do
          stub_user_mapping_chain(project, false)
        end

        it 'does not enqueue the worker to load placeholder references' do
          expect(Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

          importer.execute
        end

        it 'does not sleep' do
          allow(store).to receive(:empty?).and_return(false)

          expect(Kernel).not_to receive(:sleep)

          importer.execute
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(project).to receive(:import_data).and_return(double.as_null_object)

        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

        allow_any_instance_of(Octokit::Client).to receive(:rate_limit!).and_raise(Octokit::NotFound)
        allow(project.wiki.repository).to receive(:import_repository).and_raise(Gitlab::Git::CommandError)

        allow_any_instance_of(Octokit::Client).to receive(:user).and_return(octocat)
        allow_any_instance_of(Octokit::Client).to receive(:labels).and_return([label1, label2])
        allow_any_instance_of(Octokit::Client).to receive(:milestones).and_return([milestone, milestone])
        allow_any_instance_of(Octokit::Client).to receive(:issues).and_return([issue1, issue2])
        allow_any_instance_of(Octokit::Client).to receive(:pull_requests).and_return([pull_request, pull_request_missing_source_branch])
        allow_any_instance_of(Octokit::Client).to receive(:issues_comments).and_raise(Octokit::NotFound)
        allow_any_instance_of(Octokit::Client).to receive(:pull_requests_comments).and_return([])
        allow_any_instance_of(Octokit::Client).to receive(:last_response).and_return(double(rels: { next: nil }))
        allow_any_instance_of(Octokit::Client).to receive(:releases).and_return([release1, release2])

        allow(importer).to receive(:restore_source_branch).and_raise(StandardError, 'Some error')
      end

      it 'returns true' do
        expect(subject.execute).to eq true
      end

      it 'does not raise an error' do
        expect { subject.execute }.not_to raise_error
      end

      it 'stores error messages', :unlimited_max_formatted_output_length do
        error = {
          message: 'The remote data could not be fully imported.',
          errors: [
            { type: :label, url: "#{api_root}/repos/octocat/Hello-World/labels/bug", errors: "Validation failed: Title can't be blank, Title is invalid" },
            { type: :pull_request, url: "#{api_root}/repos/octocat/Hello-World/pulls/1347", errors: 'Some error' },
            { type: :issue, url: "#{api_root}/repos/octocat/Hello-World/issues/1348", errors: "Validation failed: Title can't be blank" },
            { type: :issues_comments, errors: 'Octokit::NotFound' },
            { type: :wiki, errors: "Gitlab::Git::CommandError" }
          ]
        }

        importer.execute

        expect(project.import_state.last_error).to eq error.to_json
      end

      context 'when comment has invalid created date' do
        let(:comment_with_invalid_date) do
          {
            html_url: "#{api_root}/repos/octocat/Hello-World/issues/1347",
            body: "I'm having a problem with this.",
            user: octocat,
            commit_id: nil,
            diff_hunk: nil,
            created_at: DateTime.strptime('1900-01-26T19:01:12Z'),
            updated_at: updated_at
          }
        end

        before do
          allow_any_instance_of(Octokit::Client).to receive(:issues_comments).and_return([comment_with_invalid_date])
        end

        it 'stores error messages' do
          importer.execute

          expect(Gitlab::Json.parse(project.import_state.last_error)).to include({
            'errors' => include(
              { "errors" => "Validation failed: Created at The created date provided is too far in the past.", "type" => "comment", "url" => "#{api_root}/repos/octocat/Hello-World/issues/1347" }
            )
          })
        end
      end
    end

    describe '#clean_up_restored_branches' do
      before do
        allow(gh_pull_request).to receive(:source_branch_exists?).at_least(:once) { false }
        allow(gh_pull_request).to receive(:target_branch_exists?).at_least(:once) { false }
      end

      context 'when pull request stills open' do
        let(:gh_pull_request) { Gitlab::LegacyGithubImport::PullRequestFormatter.new(project, pull_request) }

        it 'does not remove branches' do
          expect(subject).not_to receive(:remove_branch)
          subject.send(:clean_up_restored_branches, gh_pull_request)
        end
      end

      context 'when pull request is closed' do
        let(:gh_pull_request) { Gitlab::LegacyGithubImport::PullRequestFormatter.new(project, closed_pull_request) }

        it 'does remove branches' do
          expect(subject).to receive(:remove_branch).at_least(:twice)
          subject.send(:clean_up_restored_branches, gh_pull_request)
        end
      end
    end

    describe '#client' do
      it 'instantiates a Client' do
        allow(project).to receive(:import_data).and_return(double(credentials: credentials))
        expect(Gitlab::LegacyGithubImport::Client).to receive(:new).with(
          credentials[:user],
          { host: "#{repo_root}:443/foo", api_version: 'v1' }
        )

        subject.client
      end
    end
  end
end
