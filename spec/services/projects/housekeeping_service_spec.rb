require 'spec_helper'

describe Projects::HousekeepingService do
  subject { Projects::HousekeepingService.new(project) }
  let(:project) { create :project }

  describe 'execute' do
    before do
      project.pushes_since_gc = 3
      project.save!
    end

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
        end.not_to change { project.pushes_since_gc }.from(3)
      end
    end
  end

  describe 'needed?' do
    it 'when the count is low enough' do
      expect(subject.needed?).to eq(false)
    end

    it 'when the count is high enough' do
      allow(project).to receive(:pushes_since_gc).and_return(10)
      expect(subject.needed?).to eq(true)
    end
  end

  describe 'increment!' do
    let(:lease_key) { "project_housekeeping:increment!:#{project.id}" }

    it 'increments the pushes_since_gc counter' do
      lease = double(:lease, try_obtain: true)
      expect(Gitlab::ExclusiveLease).to receive(:new).with(lease_key, anything).and_return(lease)

      expect do
        subject.increment!
      end.to change { project.pushes_since_gc }.from(0).to(1)
    end

    it 'does not increment when no lease can be obtained' do
      lease = double(:lease, try_obtain: false)
      expect(Gitlab::ExclusiveLease).to receive(:new).with(lease_key, anything).and_return(lease)

      expect do
        subject.increment!
      end.not_to change { project.pushes_since_gc }
    end
  end
end
