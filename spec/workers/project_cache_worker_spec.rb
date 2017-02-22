require 'spec_helper'

describe ProjectCacheWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:statistics) { project.statistics }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).
        and_return(true)
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
        expect_any_instance_of(Repository).to receive(:refresh_method_caches).
          with(%i(readme)).
          and_call_original

        worker.perform(project.id, %w(readme))
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
    end
  end

  describe '#update_statistics' do
    context 'when a lease could not be obtained' do
      it 'does not update the repository size' do
        allow(worker).to receive(:try_obtain_lease_for).
          with(project.id, :update_statistics).
          and_return(false)

        expect(statistics).not_to receive(:refresh!)

        worker.update_statistics(project)
      end
    end

    context 'when a lease could be obtained' do
      it 'updates the project statistics' do
        allow(worker).to receive(:try_obtain_lease_for).
          with(project.id, :update_statistics).
          and_return(true)

        expect(statistics).to receive(:refresh!)
          .with(only: %i(repository_size))
          .and_call_original

        worker.update_statistics(project, %i(repository_size))
      end
    end
  end
end
