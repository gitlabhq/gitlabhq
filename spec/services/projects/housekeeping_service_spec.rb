require 'spec_helper'

describe Projects::HousekeepingService do
  subject { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  before do
    project.reset_pushes_since_gc
  end

  after do
    project.reset_pushes_since_gc
  end

  describe '#execute' do
    it 'enqueues a sidekiq job' do
      expect(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
      expect(subject).to receive(:lease_key).and_return(:the_lease_key)
      expect(subject).to receive(:task).and_return(:the_task)
      expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :the_task, :the_lease_key, :the_uuid)

      subject.execute

      expect(project.reload.pushes_since_gc).to eq(0)
    end

    it 'yields the block if given' do
      expect do |block|
        subject.execute(&block)
      end.to yield_with_no_args
    end

    context 'when no lease can be obtained' do
      before do
        expect(subject).to receive(:try_obtain_lease).and_return(false)
      end

      it 'does not enqueue a job' do
        expect(GitGarbageCollectWorker).not_to receive(:perform_async)

        expect { subject.execute }.to raise_error(Projects::HousekeepingService::LeaseTaken)
      end

      it 'does not reset pushes_since_gc' do
        expect do
          expect { subject.execute }.to raise_error(Projects::HousekeepingService::LeaseTaken)
        end.not_to change { project.pushes_since_gc }
      end

      it 'does not yield' do
        expect do |block|
          expect { subject.execute(&block) }
            .to raise_error(Projects::HousekeepingService::LeaseTaken)
        end.not_to yield_with_no_args
      end
    end
  end

  describe '#needed?' do
    it 'when the count is low enough' do
      expect(subject.needed?).to eq(false)
    end

    it 'when the count is high enough' do
      allow(project).to receive(:pushes_since_gc).and_return(10)
      expect(subject.needed?).to eq(true)
    end
  end

  describe '#increment!' do
    it 'increments the pushes_since_gc counter' do
      expect do
        subject.increment!
      end.to change { project.pushes_since_gc }.from(0).to(1)
    end
  end

  it 'goes through all three housekeeping tasks, executing only the highest task when there is overlap' do
    allow(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
    allow(subject).to receive(:lease_key).and_return(:the_lease_key)

    # At push 200
    expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :gc, :the_lease_key, :the_uuid)
      .exactly(1).times
    # At push 50, 100, 150
    expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :full_repack, :the_lease_key, :the_uuid)
      .exactly(3).times
    # At push 10, 20, ... (except those above)
    expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :incremental_repack, :the_lease_key, :the_uuid)
      .exactly(16).times

    201.times do
      subject.increment!
      subject.execute if subject.needed?
    end

    expect(project.pushes_since_gc).to eq(1)
  end
end
