# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchHooksService, :clean_gitlab_redis_shared_state do
  include RepoHelpers
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  let(:branch) { project.default_branch }
  let(:ref) { "refs/heads/#{branch}" }
  let(:commit_id) { sample_commit.id }
  let(:commit) { project.commit(commit_id) }
  let(:oldrev) { commit.parent_id }
  let(:newrev) { commit.id }

  let(:service) do
    described_class.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref })
  end

  describe "Git Push Data" do
    subject(:push_data) { service.send(:push_data) }

    it 'has expected push data attributes' do
      is_expected.to match a_hash_including(
        object_kind: 'push',
        before: oldrev,
        after: newrev,
        ref: ref,
        user_id: user.id,
        user_name: user.name,
        project_id: project.id
      )
    end

    context "with repository data" do
      subject { push_data[:repository] }

      it 'has expected attributes' do
        is_expected.to match a_hash_including(
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url
        )
      end
    end

    context "with commits" do
      subject { push_data[:commits] }

      it { is_expected.to be_an(Array) }

      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end

      context "the commit" do
        subject { push_data[:commits].first }

        it { expect(subject[:timestamp].in_time_zone).to eq(commit.date.in_time_zone) }

        it 'includes expected commit data' do
          is_expected.to match a_hash_including(
            id: commit.id,
            message: commit.safe_message,
            url: [
              Gitlab.config.gitlab.url,
              project.namespace.to_param,
              project.to_param,
              '-',
              'commit',
              commit.id
            ].join('/')
          )
        end

        context "with a author" do
          subject { push_data[:commits].first[:author] }

          it 'includes expected author data' do
            is_expected.to match a_hash_including(
              name: commit.author_name,
              email: commit.author_email
            )
          end
        end
      end
    end
  end

  describe 'Push Event' do
    let(:event) { Event.pushed_action.first }

    subject(:execute_service) { service.execute }

    context "with an existing branch" do
      it 'generates a push event with one commit' do
        execute_service

        expect(event).to be_an_instance_of(PushEvent)
        expect(event.project).to eq(project)
        expect(event).to be_pushed_action
        expect(event.push_event_payload).to be_an_instance_of(PushEventPayload)
        expect(event.push_event_payload.commit_from).to eq(oldrev)
        expect(event.push_event_payload.commit_to).to eq(newrev)
        expect(event.push_event_payload.commit_title).to eq('Change some files')
        expect(event.push_event_payload.ref).to eq('master')
        expect(event.push_event_payload.commit_count).to eq(1)
      end

      context 'with changing CI config' do
        before do
          allow_next_instance_of(Gitlab::Git::Diff) do |diff|
            allow(diff).to receive(:new_path).and_return('.gitlab-ci.yml')
          end
        end

        let!(:commit_author) { create(:user, email: sample_commit.author_email) }

        let(:tracking_params) do
          ['o_pipeline_authoring_unique_users_committing_ciconfigfile', values: commit_author.id]
        end

        it 'tracks the event' do
          time = Time.zone.now

          execute_service

          expect(Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'o_pipeline_authoring_unique_users_committing_ciconfigfile', start_date: time, end_date: time + 7.days)).to eq(1)
        end

        context 'when usage ping is disabled' do
          before do
            stub_application_setting(usage_ping_enabled: false)
          end

          it 'does not track the event' do
            execute_service

            expect(Gitlab::UsageDataCounters::HLLRedisCounter)
              .not_to receive(:track_event).with(*tracking_params)
          end
        end

        context 'when the branch is not the main branch' do
          let(:branch) { 'feature' }

          it 'does not track the event' do
            execute_service

            expect(Gitlab::UsageDataCounters::HLLRedisCounter)
              .not_to receive(:track_event).with(*tracking_params)
          end
        end

        context 'when the CI config is a different path' do
          before do
            project.ci_config_path = 'config/ci.yml'
          end

          it 'does not track the event' do
            execute_service

            expect(Gitlab::UsageDataCounters::HLLRedisCounter)
              .not_to receive(:track_event).with(*tracking_params)
          end
        end
      end
    end

    context "with a new branch" do
      let(:oldrev) { Gitlab::Git::BLANK_SHA }

      it 'generates a push event with more than one commit' do
        execute_service

        expect(event).to be_an_instance_of(PushEvent)
        expect(event.project).to eq(project)
        expect(event).to be_pushed_action
        expect(event.push_event_payload).to be_an_instance_of(PushEventPayload)
        expect(event.push_event_payload.commit_from).to be_nil
        expect(event.push_event_payload.commit_to).to eq(newrev)
        expect(event.push_event_payload.commit_title).to eq('Initial commit')
        expect(event.push_event_payload.ref).to eq('master')
        expect(event.push_event_payload.commit_count).to be > 1
      end
    end

    context 'removing a branch' do
      let(:newrev) { Gitlab::Git::BLANK_SHA }

      it 'generates a push event with no commits' do
        execute_service

        expect(event).to be_an_instance_of(PushEvent)
        expect(event.project).to eq(project)
        expect(event).to be_pushed_action
        expect(event.push_event_payload).to be_an_instance_of(PushEventPayload)
        expect(event.push_event_payload.commit_from).to eq(oldrev)
        expect(event.push_event_payload.commit_to).to be_nil
        expect(event.push_event_payload.ref).to eq('master')
        expect(event.push_event_payload.commit_count).to eq(0)
      end
    end
  end

  describe 'Invalidating project cache' do
    let(:commit_id) do
      project.repository.update_file(
        user, 'README.md', '', message: 'Update', branch_name: branch
      )
    end

    let(:blank_sha) { Gitlab::Git::BLANK_SHA }

    def clears_cache(extended: [])
      expect(service).to receive(:invalidated_file_types).and_return(extended)

      if extended.present?
        expect(ProjectCacheWorker)
          .to receive(:perform_async)
          .with(project.id, extended, [], false)
      end

      service.execute
    end

    def clears_extended_cache
      clears_cache(extended: %i[readme])
    end

    context 'on default branch' do
      context 'create' do
        # FIXME: When creating the default branch,the cache worker runs twice
        before do
          allow(ProjectCacheWorker).to receive(:perform_async)
        end

        let(:oldrev) { blank_sha }

        it { clears_cache }
      end

      context 'update' do
        it { clears_extended_cache }
      end

      context 'remove' do
        let(:newrev) { blank_sha }

        # TODO: this case should pass, but we only take account of added files
        it { clears_cache }
      end
    end

    context 'on ordinary branch' do
      let(:branch) { 'fix' }

      context 'create' do
        let(:oldrev) { blank_sha }

        it { clears_cache }
      end

      context 'update' do
        it { clears_cache }
      end

      context 'remove' do
        let(:newrev) { blank_sha }

        it { clears_cache }
      end
    end
  end

  describe 'signatures' do
    context 'when the commit has a signature' do
      context 'when the signature is already cached' do
        before do
          create(:gpg_signature, commit_sha: commit.id)
        end

        it 'does not queue a CreateCommitSignatureWorker' do
          expect(CreateCommitSignatureWorker).not_to receive(:perform_async)

          service.execute
        end
      end

      context 'when the signature is not yet cached' do
        it 'queues a CreateCommitSignatureWorker' do
          expect(CreateCommitSignatureWorker).to receive(:perform_async).with([commit.id], project.id)

          service.execute
        end

        it 'can queue several commits to create the gpg signature' do
          allow(Gitlab::Git::Commit)
            .to receive(:shas_with_signatures)
            .and_return([sample_commit.id, another_sample_commit.id])

          expect(CreateCommitSignatureWorker)
            .to receive(:perform_async)
            .with([sample_commit.id, another_sample_commit.id], project.id)

          service.execute
        end
      end
    end

    context 'when the commit does not have a signature' do
      before do
        allow(Gitlab::Git::Commit)
          .to receive(:shas_with_signatures)
          .with(project.repository, [sample_commit.id])
          .and_return([])
      end

      it 'does not queue a CreateCommitSignatureWorker' do
        expect(CreateCommitSignatureWorker)
          .not_to receive(:perform_async)
          .with(sample_commit.id, project.id)

        service.execute
      end
    end
  end

  describe 'Processing commit messages' do
    # Create 6 commits, 3 of which have references. Limiting to 4 commits, we
    # expect to see two commit message processors enqueued.
    let!(:commit_ids) do
      Array.new(6) do |i|
        message = "Issue #{'#' if i.even?}#{i}"
        project.repository.update_file(
          user, 'README.md', '', message: message, branch_name: branch
        )
      end
    end

    let(:oldrev) { project.commit(commit_ids.first).parent_id }
    let(:newrev) { commit_ids.last }

    before do
      stub_const("::Git::BaseHooksService::PROCESS_COMMIT_LIMIT", 4)
    end

    context 'creating the default branch' do
      let(:oldrev) { Gitlab::Git::BLANK_SHA }

      it 'processes a limited number of commit messages' do
        expect(ProcessCommitWorker).to receive(:perform_async).twice

        service.execute
      end
    end

    context 'updating the default branch' do
      it 'processes a limited number of commit messages' do
        expect(ProcessCommitWorker).to receive(:perform_async).twice

        service.execute
      end
    end

    context 'removing the default branch' do
      let(:newrev) { Gitlab::Git::BLANK_SHA }

      it 'does not process commit messages' do
        expect(ProcessCommitWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'creating a normal branch' do
      let(:branch) { 'fix' }
      let(:oldrev) { Gitlab::Git::BLANK_SHA }

      it 'processes a limited number of commit messages' do
        expect(ProcessCommitWorker).to receive(:perform_async).twice

        service.execute
      end
    end

    context 'updating a normal branch' do
      let(:branch) { 'fix' }

      it 'processes a limited number of commit messages' do
        expect(ProcessCommitWorker).to receive(:perform_async).twice

        service.execute
      end
    end

    context 'removing a normal branch' do
      let(:branch) { 'fix' }
      let(:newrev) { Gitlab::Git::BLANK_SHA }

      it 'does not process commit messages' do
        expect(ProcessCommitWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'when the project is forked', :sidekiq_might_not_need_inline do
      let(:upstream_project) { project }
      let(:forked_project) { fork_project(upstream_project, user, repository: true, using_service: true) }

      let!(:forked_service) do
        described_class.new(forked_project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref })
      end

      context 'when commits already exists in the upstream project' do
        it 'does not process commit messages' do
          expect(ProcessCommitWorker).not_to receive(:perform_async)

          forked_service.execute
        end
      end

      context 'when a commit does not exist in the upstream repo' do
        # On top of the existing 6 commits, 3 of which have references,
        # create 2 more, 1 of which has a reference. Limiting to 4 commits, we
        # expect to see one commit message processor enqueued.
        let!(:forked_commit_ids) do
          Array.new(2) do |i|
            message = "Issue #{'#' if i.even?}#{i}"
            forked_project.repository.update_file(
              user, 'README.md', '', message: message, branch_name: branch
            )
          end
        end

        let(:newrev) { forked_commit_ids.last }

        it 'processes the commit message' do
          expect(ProcessCommitWorker).to receive(:perform_async).once

          forked_service.execute
        end
      end

      context 'when the upstream project no longer exists' do
        it 'processes the commit messages' do
          upstream_project.destroy!

          expect(ProcessCommitWorker).to receive(:perform_async).twice

          forked_service.execute
        end
      end
    end
  end

  describe 'New branch detection' do
    let(:branch) { 'fix' }

    context 'oldrev is the blank SHA' do
      let(:oldrev) { Gitlab::Git::BLANK_SHA }

      it 'is treated as a new branch' do
        expect(service).to receive(:branch_create_hooks)

        service.execute
      end
    end

    context 'oldrev is set' do
      context 'Gitaly does not know about the branch' do
        it 'is treated as a new branch' do
          allow(project.repository).to receive(:branch_names) { [] }

          expect(service).to receive(:branch_create_hooks)

          service.execute
        end
      end

      context 'Gitaly knows about the branch' do
        it 'is not treated as a new branch' do
          expect(service).not_to receive(:branch_create_hooks)

          service.execute
        end
      end
    end
  end

  describe 'Metrics dashboard sync' do
    shared_examples 'trigger dashboard sync' do
      it 'imports metrics to database' do
        expect(Metrics::Dashboard::SyncDashboardsWorker).to receive(:perform_async)

        service.execute
      end
    end

    shared_examples 'no dashboard sync' do
      it 'does not sync metrics to database' do
        expect(Metrics::Dashboard::SyncDashboardsWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    def change_repository(**changes)
      actions = changes.flat_map do |(action, paths)|
        Array(paths).flat_map do |file_path|
          { action: action, file_path: file_path, content: SecureRandom.hex }
        end
      end

      project.repository.multi_action(
        user, message: 'message', branch_name: branch, actions: actions
      )
    end

    let(:charts) { '.gitlab/dashboards/charts.yml' }
    let(:readme) { 'README.md' }
    let(:commit_id) { change_repository(**commit_changes) }

    context 'with default branch' do
      context 'when adding files' do
        let(:new_file) { 'somenewfile.md' }

        context 'also related' do
          let(:commit_changes) { { create: [charts, new_file] } }

          include_examples 'trigger dashboard sync'
        end

        context 'only unrelated' do
          let(:commit_changes) { { create: new_file } }

          include_examples 'no dashboard sync'
        end
      end

      context 'when deleting files' do
        before do
          change_repository(create: charts)
        end

        context 'also related' do
          let(:commit_changes) { { delete: [charts, readme] } }

          include_examples 'trigger dashboard sync'
        end

        context 'only unrelated' do
          let(:commit_changes) { { delete: readme } }

          include_examples 'no dashboard sync'
        end
      end

      context 'when updating files' do
        before do
          change_repository(create: charts)
        end

        context 'also related' do
          let(:commit_changes) { { update: [charts, readme] } }

          include_examples 'trigger dashboard sync'
        end

        context 'only unrelated' do
          let(:commit_changes) { { update: readme } }

          include_examples 'no dashboard sync'
        end
      end

      context 'without changes' do
        let(:commit_changes) { {} }

        include_examples 'no dashboard sync'
      end
    end

    context 'with other branch' do
      let(:branch) { 'fix' }
      let(:commit_changes) { { create: charts } }

      include_examples 'no dashboard sync'
    end
  end
end
