require 'spec_helper'

describe ProjectCacheWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '.perform_async' do
    it 'schedules the job when no lease exists' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:exists?).
        and_return(false)

      expect_any_instance_of(described_class).to receive(:perform)

      described_class.perform_async(project.id)
    end

    it 'does not schedule the job when a lease exists' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:exists?).
        and_return(true)

      expect_any_instance_of(described_class).not_to receive(:perform)

      described_class.perform_async(project.id)
    end
  end

  describe '#perform' do
    context 'when an exclusive lease can be obtained' do
      before do
        allow(subject).to receive(:try_obtain_lease_for).with(project.id).
          and_return(true)
      end

      it 'updates project cache data' do
        expect_any_instance_of(Repository).to receive(:size)
        expect_any_instance_of(Repository).to receive(:commit_count)

        expect_any_instance_of(Project).to receive(:update_repository_size)
        expect_any_instance_of(Project).to receive(:update_commit_count)

        expect_any_instance_of(Repository).to receive(:build_cache).and_call_original

        subject.perform(project.id)
      end

      it 'handles missing repository data' do
        expect_any_instance_of(Repository).to receive(:exists?).and_return(false)
        expect_any_instance_of(Repository).not_to receive(:size)

        subject.perform(project.id)
      end

      context 'when in Geo secondary node' do
        before do
          allow(Gitlab::Geo).to receive(:secondary?) { true }
        end

        it 'updates only non database cache' do
          expect_any_instance_of(Repository).to receive(:build_cache).and_call_original

          expect_any_instance_of(Project).not_to receive(:update_repository_size)
          expect_any_instance_of(Project).not_to receive(:update_commit_count)

          subject.perform(project.id)
        end
      end
    end

    context 'when an exclusive lease can not be obtained' do
      it 'does nothing' do
        allow(subject).to receive(:try_obtain_lease_for).with(project.id).
          and_return(false)

        expect(subject).not_to receive(:update_caches)

        subject.perform(project.id)
      end
    end
  end
end
