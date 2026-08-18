# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::KeepAroundRefsWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:merge_request_diff) { merge_request.merge_request_diff }

  let(:worker) { described_class.new }

  it 'deduplicates identical jobs until they have executed' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  # A Sidekiq retry is the expected outcome of a failed write, not a new fault:
  # `Gitlab::Git::KeepAround` has already reported the underlying Gitaly error.
  it 'raises an error that is kept out of Sentry and the execution SLI' do
    expect(described_class::KeepAroundRefsError.new)
      .to be_a(::Gitlab::SidekiqMiddleware::RetryError)
  end

  describe '#perform' do
    let(:project_ids) { [project.id] }
    let(:shas) { [merge_request_diff.start_commit_sha, merge_request_diff.head_commit_sha] }
    let(:source) { 'MergeRequestDiff' }

    context 'with missing required parameters' do
      it 'does nothing when project_ids is empty' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform([], shas, source)
      end

      it 'does nothing when shas is empty' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(project_ids, [], source)
      end

      it 'does nothing when project_ids is nil' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(nil, shas, source)
      end

      it 'does nothing when shas is nil' do
        expect(MergeRequests::KeepAroundRefsService).not_to receive(:new)

        worker.perform(project_ids, nil, source)
      end
    end

    context 'with valid arguments' do
      it 'calls the keep around refs service' do
        expect_next_instance_of(
          MergeRequests::KeepAroundRefsService,
          project_ids: project_ids,
          shas: shas,
          source: source
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        worker.perform(project_ids, shas, source)
      end

      it 'handles a single project_id' do
        expect_next_instance_of(
          MergeRequests::KeepAroundRefsService,
          project_ids: [project.id],
          shas: [merge_request_diff.head_commit_sha],
          source: 'MergeRequest'
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        worker.perform([project.id], [merge_request_diff.head_commit_sha], 'MergeRequest')
      end
    end

    context 'when the service reports unwritten SHAs' do
      before do
        allow_next_instance_of(MergeRequests::KeepAroundRefsService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(
              message: 'Keep-around references were not written',
              payload: { unwritten_shas: [shas.first] }
            )
          )
        end
      end

      it 'raises so that the job is retried' do
        expect { worker.perform(project_ids, shas, source) }
          .to raise_error(described_class::KeepAroundRefsError, 'Keep-around references were not written')
      end

      it 'logs the SHAs that could not be written' do
        expect(worker.logger).to receive(:warn).with(
          a_hash_including(
            'message' => 'Keep-around references were not written.',
            'project_ids' => project_ids,
            'shas' => [shas.first]
          )
        )

        expect { worker.perform(project_ids, shas, source) }
          .to raise_error(described_class::KeepAroundRefsError)
      end
    end

    # The flag is applied per project by `MergeRequests::KeepAroundRefsService`,
    # which is the only place a failed SHA can be attributed to one, so a
    # disabled project reaches the worker with nothing reported.
    context 'when every keep-around ref was written' do
      before do
        allow_next_instance_of(MergeRequests::KeepAroundRefsService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.success)
        end
      end

      it 'does not raise' do
        expect { worker.perform(project_ids, shas, source) }.not_to raise_error
      end

      it 'does not log' do
        expect(worker.logger).not_to receive(:warn)

        worker.perform(project_ids, shas, source)
      end
    end

    # With the flag off for every project in the job the service keeps its old
    # return value, which is not a `ServiceResponse` and must not be treated as one.
    context 'when the service returns no ServiceResponse' do
      [nil, [], %w[repository]].each do |value|
        context "when it returns #{value.inspect}" do
          before do
            allow_next_instance_of(MergeRequests::KeepAroundRefsService) do |service|
              allow(service).to receive(:execute).and_return(value)
            end
          end

          it 'does not raise or log' do
            expect(worker.logger).not_to receive(:warn)

            expect { worker.perform(project_ids, shas, source) }.not_to raise_error
          end
        end
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project_ids, shas, source] }
    end
  end
end
