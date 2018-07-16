require 'spec_helper'

describe ProjectCacheWorker do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:statistics) { project.statistics }
  let(:lease_key) { "project_cache_worker:#{project.id}:update_statistics" }
  let(:lease_timeout) { ProjectCacheWorker::LEASE_TIMEOUT }

  describe '#perform' do
    before do
      stub_exclusive_lease(lease_key, timeout: lease_timeout)
    end

    context 'with a non-existing project' do
      it 'does nothing' do
        expect(worker).not_to receive(:update_statistics)

        worker.perform(-1)
      end
    end

    context 'with an existing project without a repository' do
      it 'does nothing' do
        allow_any_instance_of(Repository).to receive(:exists?).and_return(false)

        expect(worker).not_to receive(:update_statistics)

        worker.perform(project.id)
      end
    end

    context 'with an existing project' do
      it 'updates the project statistics' do
        expect(worker).to receive(:update_statistics)
          .with(kind_of(Project), %i(repository_size))
          .and_call_original

        worker.perform(project.id, [], %w(repository_size))
      end

      it 'refreshes the method caches' do
        expect_any_instance_of(Repository).to receive(:refresh_method_caches)
          .with(%i(readme))
          .and_call_original

        worker.perform(project.id, %w(readme))
      end

      context 'with plain readme' do
        it 'refreshes the method caches' do
          allow(MarkupHelper).to receive(:gitlab_markdown?).and_return(false)
          allow(MarkupHelper).to receive(:plain?).and_return(true)

          expect_any_instance_of(Repository).to receive(:refresh_method_caches)
                                                  .with(%i(readme))
                                                  .and_call_original
          worker.perform(project.id, %w(readme))
        end
      end
    end
  end

  describe '#update_statistics' do
    context 'when a lease could not be obtained' do
      it 'does not update the repository size' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(statistics).not_to receive(:refresh!)

        worker.update_statistics(project)
      end
    end

    context 'when a lease could be obtained' do
      it 'updates the project statistics' do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)

        expect(statistics).to receive(:refresh!)
          .with(only: %i(repository_size))
          .and_call_original

        worker.update_statistics(project, %i(repository_size))
      end
    end
  end
end
