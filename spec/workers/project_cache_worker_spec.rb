require 'spec_helper'

describe ProjectCacheWorker do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:statistics) { project.statistics }
  let(:lease_key) { "project_cache_worker:#{project.id}:update_statistics" }
  let(:lease_timeout) { ProjectCacheWorker::LEASE_TIMEOUT }

  before do
    stub_exclusive_lease(lease_key, timeout: lease_timeout)

    allow(Project).to receive(:find_by)
                        .with(id: project.id)
                        .and_return(project)
  end

  describe '#perform' do
    context 'with a non-existing project' do
      it 'does not update statistic' do
        allow(Project).to receive(:find_by).with(id: -1).and_return(nil)

        expect(subject).not_to receive(:update_statistics)

        subject.perform(-1)
      end
    end

    context 'with an existing project without a repository' do
      it 'does not update statistics' do
        allow(project.repository).to receive(:exists?).and_return(false)

        expect(subject).not_to receive(:update_statistics)

        subject.perform(project.id)
      end
    end

    context 'with an existing project' do
      it 'updates the project statistics' do
        expect(subject).to receive(:update_statistics)
                             .with(%w(repository_size))
                             .and_call_original

        subject.perform(project.id, [], %w(repository_size))
      end

      it 'refreshes the method caches' do
        expect(project.repository).to receive(:refresh_method_caches)
                                        .with(%i(readme))
                                        .and_call_original

        subject.perform(project.id, %w(readme))
      end

      context 'when in Geo secondary node' do
        before do
          allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
        end

        it 'updates only non database cache' do
          expect_any_instance_of(Repository).to receive(:refresh_method_caches)
            .and_call_original

          expect_any_instance_of(Project).not_to receive(:update_repository_size)
          expect_any_instance_of(Project).not_to receive(:update_commit_count)

          subject.perform(project.id)
        end
      end

      context 'with plain readme' do
        it 'refreshes the method caches' do
          allow(MarkupHelper).to receive(:gitlab_markdown?).and_return(false)
          allow(MarkupHelper).to receive(:plain?).and_return(true)

          expect(project.repository).to receive(:refresh_method_caches)
                                          .with(%i(readme))
                                          .and_call_original

          subject.perform(project.id, %w(readme))
        end
      end
    end

    context 'when a lease could not be obtained' do
      it 'does not update the repository size' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(project.statistics).not_to receive(:refresh!)

        subject.perform(project.id, [], %w(repository_size))
      end
    end

    context 'when a lease could be obtained' do
      it 'updates the project statistics' do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)

        expect(project.statistics).to receive(:refresh!)
                                        .with(only: %i(repository_size))
                                        .and_call_original

        subject.perform(project.id, [], %i(repository_size))
      end

      it 'cancels the lease after statistics has been updated' do
        expect(subject).to receive(:release_lease).with('uuid')

        subject.perform(project.id, [], %i(repository_size))
      end
    end
  end
end
