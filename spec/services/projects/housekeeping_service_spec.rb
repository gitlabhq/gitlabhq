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
      expect(GitlabShellOneShotWorker).to receive(:perform_async).with(:gc, project.path_with_namespace)

      subject.execute
      expect(project.pushes_since_gc).to eq(0)
    end

    it 'does not enqueue a job when no lease can be obtained' do
      expect(subject).to receive(:try_obtain_lease).and_return(false)
      expect(GitlabShellOneShotWorker).not_to receive(:perform_async)

      expect { subject.execute }.to raise_error(Projects::HousekeepingService::LeaseTaken)
      expect(project.pushes_since_gc).to eq(0)
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
    it 'increments the pushes_since_gc counter' do
      expect(project.pushes_since_gc).to eq(0)
      subject.increment!
      expect(project.pushes_since_gc).to eq(1)
    end
  end
end
