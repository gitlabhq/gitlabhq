# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::KeepAroundRefsService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:merge_request_diff) { merge_request.merge_request_diff }

  let(:start_commit_sha) { merge_request_diff.start_commit_sha }
  let(:head_commit_sha) { merge_request_diff.head_commit_sha }
  let(:source) { 'MergeRequestDiff' }

  describe '#execute' do
    context 'with a single project' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      it 'calls keep_around on the repository with the correct SHAs and source' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([])

        service.execute

        expect(repo).to have_received(:keep_around).with(
          start_commit_sha,
          head_commit_sha,
          source: 'MergeRequestDiff',
          retry_failed_writes: true
        ).once
      end
    end

    context 'with two different projects' do
      let_it_be(:source_project) { fork_project(project, nil, repository: true) }

      subject(:service) do
        described_class.new(
          project_ids: [project.id, source_project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      it 'calls keep_around on both repositories' do
        repo1 = instance_double(Repository)
        repo2 = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id, source_project.id]).and_return([project, source_project])
        allow(project).to receive(:repository).and_return(repo1)
        allow(source_project).to receive(:repository).and_return(repo2)
        allow(repo1).to receive(:keep_around).and_return([])
        allow(repo2).to receive(:keep_around).and_return([])

        service.execute

        expect(repo1).to have_received(:keep_around).with(
          start_commit_sha, head_commit_sha, source: 'MergeRequestDiff', retry_failed_writes: true
        )
        expect(repo2).to have_received(:keep_around).with(
          start_commit_sha, head_commit_sha, source: 'MergeRequestDiff', retry_failed_writes: true
        )
      end
    end

    context 'when a ref could not be written' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      it 'returns an error naming the SHAs that failed' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([head_commit_sha])

        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('Keep-around references were not written')
        expect(response.payload[:unwritten_shas]).to eq([head_commit_sha])
      end

      # The worker only sees the job's full `project_ids`, so this is the only
      # place an unwritten SHA can be attributed to a repository.
      it 'logs the failing project under the write-failure message' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([head_commit_sha])

        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_hash_including(
            message: 'Keep-around reference write failed',
            project_id: project.id,
            shas: [head_commit_sha],
            source: source
          )
        )

        service.execute
      end
    end

    context 'when the retry_failed_keep_around_ref_writes flag is disabled' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      before do
        stub_feature_flags(retry_failed_keep_around_ref_writes: false)
      end

      # The old path keeps its original return value, which the worker ignores.
      it 'returns no ServiceResponse, so the worker does not retry' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([head_commit_sha])

        expect(service.execute).not_to be_a(ServiceResponse)
      end

      it 'does not log' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([head_commit_sha])

        expect(Gitlab::AppLogger).not_to receive(:warn)

        service.execute
      end
    end

    context 'when the flag is enabled for only one project of a fork merge request' do
      let_it_be(:source_project) { fork_project(project, nil, repository: true) }

      let(:repo1) { instance_double(Repository) }
      let(:repo2) { instance_double(Repository) }

      subject(:service) do
        described_class.new(
          project_ids: [project.id, source_project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      before do
        stub_feature_flags(retry_failed_keep_around_ref_writes: project)

        allow(Project).to receive(:id_in).with([project.id, source_project.id]).and_return([project, source_project])
        allow(project).to receive(:repository).and_return(repo1)
        allow(source_project).to receive(:repository).and_return(repo2)
        allow(repo1).to receive(:keep_around).and_return([start_commit_sha])
        allow(repo2).to receive(:keep_around).and_return([head_commit_sha])
      end

      it 'reports the failure only for the enabled project' do
        expect(service.execute.payload[:unwritten_shas]).to eq([start_commit_sha])
      end

      it 'logs only the enabled project' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_hash_including(project_id: project.id, shas: [start_commit_sha])
        ).once

        service.execute
      end

      # The reason the split is per project: skipping the disabled project's write here
      # would silently leave a fork merge request's source commits unprotected.
      it 'still writes the refs for the disabled project' do
        service.execute

        expect(repo2).to have_received(:keep_around).with(start_commit_sha, head_commit_sha, source: source)
      end
    end

    # The worker's `deduplicate :until_executed` takes its key in client middleware,
    # which a Sidekiq retry never runs. The lease is what stops a retrying job from
    # writing the same refs as an identical job enqueued while it was retrying.
    describe 'the write lease', :clean_gitlab_redis_shared_state do
      let(:repo) { instance_double(Repository) }

      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      before do
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([])
      end

      def obtain_lease(shas: [start_commit_sha, head_commit_sha])
        key = described_class.new(project_ids: [project.id], shas: shas, source: source)
                             .send(:lease_key, project)

        Gitlab::ExclusiveLease.new(key, timeout: described_class::LEASE_TTL).try_obtain
      end

      it 'derives the same key regardless of SHA order, so a retry collides with its twin' do
        expect(obtain_lease).to be_present
        expect(obtain_lease(shas: [head_commit_sha, start_commit_sha])).to be_falsey
      end

      it 'keys per project, so a fork merge request does not self-contend' do
        other = described_class.new(project_ids: [project.id], shas: [start_commit_sha], source: source)

        expect(other.send(:lease_key, project)).not_to eq(service.send(:lease_key, project))
      end

      # Reporting success here would drop the write for good whenever the lease
      # holder was interrupted before finishing, which is the exact failure this
      # merge request exists to prevent.
      it 'reports the SHAs as unwritten when another job holds the lease' do
        expect(obtain_lease).to be_present

        expect(service.execute.payload[:unwritten_shas]).to eq([start_commit_sha, head_commit_sha])
        expect(repo).not_to have_received(:keep_around)
      end

      # A distinct message rather than a `reason` field: Labkit's field
      # standardization deprecates `reason`, and this is what a log query needs
      # to separate contention from a real write failure.
      it 'logs contention under its own message' do
        expect(obtain_lease).to be_present

        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_hash_including(
            message: 'Keep-around reference write skipped, lease already held',
            project_id: project.id,
            shas: [start_commit_sha, head_commit_sha]
          )
        )

        service.execute
      end

      it 'releases the lease after a successful write' do
        service.execute

        expect(obtain_lease).to be_present
      end

      it 'releases the lease when the write raises' do
        allow(repo).to receive(:keep_around).and_raise(Gitlab::Git::CommandError)

        expect { service.execute }.to raise_error(Gitlab::Git::CommandError)
        expect(obtain_lease).to be_present
      end

      context 'when the retry_failed_keep_around_ref_writes flag is disabled' do
        before do
          stub_feature_flags(retry_failed_keep_around_ref_writes: false)
        end

        it 'takes no lease and writes regardless of one being held' do
          expect(obtain_lease).to be_present

          expect(service.execute).not_to be_a(ServiceResponse)
          expect(repo).to have_received(:keep_around)
        end
      end
    end

    context 'when keep-around refs are disabled' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha],
          source: source
        )
      end

      before do
        allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
        stub_feature_flags(disable_keep_around_refs: true)
      end

      # Anything reported here would make `MergeRequests::KeepAroundRefsWorker`
      # raise and burn its retries for every merge request while the kill-switch
      # is on, so the two flags have to compose.
      it 'succeeds, so the worker does not retry' do
        expect(service.execute).to be_success
      end
    end

    context 'with non-existing project ID' do
      subject(:service) do
        described_class.new(
          project_ids: [non_existing_record_id],
          shas: [start_commit_sha],
          source: source
        )
      end

      it 'does not raise an error' do
        expect { service.execute }.not_to raise_error
      end
    end

    context 'with empty shas' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [],
          source: source
        )
      end

      it 'does not query for projects' do
        expect(Project).not_to receive(:id_in)

        service.execute
      end
    end

    context 'when source is MergeRequest' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha],
          source: 'MergeRequest'
        )
      end

      it 'passes the correct source' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around).and_return([])

        service.execute

        expect(repo).to have_received(:keep_around).with(
          start_commit_sha,
          source: 'MergeRequest',
          retry_failed_writes: true
        )
      end
    end
  end
end
