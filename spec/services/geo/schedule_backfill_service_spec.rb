require 'spec_helper'

describe Geo::ScheduleBackfillService, services: true do
  subject { Geo::ScheduleBackfillService.new(geo_node.id) }
  let(:geo_node) { create(:geo_node) }

  describe '#execute' do
    it 'schedules the backfill service' do
      Sidekiq::Worker.clear_all

      Sidekiq::Testing.fake! do
        2.times do
          create(:project)
        end

        expect{ subject.execute }.to change(GeoBackfillWorker.jobs, :size).by(2)
      end
    end
  end
end
