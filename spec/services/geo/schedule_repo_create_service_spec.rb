require 'spec_helper'

describe Geo::ScheduleRepoCreateService do
  let(:project) { create(:project) }
  subject { described_class.new(project_id: project.id) }

  describe '#execute' do
    it 'schedules the repository creation' do
      Sidekiq::Worker.clear_all

      Sidekiq::Testing.fake! do
        expect{ subject.execute }.to change(GeoRepositoryCreateWorker.jobs, :size).by(1)
      end
    end
  end
end
