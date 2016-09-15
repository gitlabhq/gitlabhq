require 'spec_helper'

describe Projects::HousekeepingService do
  subject { Projects::HousekeepingService.new(project) }
  let(:project) { create :project }

  after do
    project.reset_pushes_since_gc
  end

  describe '#execute' do
    it 'enqueues a sidekiq job' do
      expect(subject).to receive(:try_obtain_lease).and_return(true)
      expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id)

      subject.execute
      expect(project.reload.pushes_since_gc).to eq(0)
    end

    context 'when no lease can be obtained' do
      before(:each) do
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
end
