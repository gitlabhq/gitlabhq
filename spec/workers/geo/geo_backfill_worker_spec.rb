require 'spec_helper'

describe Geo::GeoBackfillWorker, services: true do
  let!(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let!(:secondary) { create(:geo_node, :current) }
  let!(:projects)  { create_list(:empty_project, 2) }

  subject { described_class.new }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    it 'performs Geo::RepositoryBackfillService for each project' do
      expect(Geo::RepositoryBackfillService).to receive(:new).twice.and_return(spy)

      subject.perform
    end

    it 'does not perform Geo::RepositoryBackfillService when tracking DB is not available' do
      allow(Rails.configuration).to receive(:respond_to?).with(:geo_database) { false }

      expect(Geo::RepositoryBackfillService).not_to receive(:new)

      subject.perform
    end

    it 'does not perform Geo::RepositoryBackfillService when primary node does not exists' do
      allow(Gitlab::Geo).to receive(:primary_node) { nil }

      expect(Geo::RepositoryBackfillService).not_to receive(:new)

      subject.perform
    end

    it 'does not perform Geo::RepositoryBackfillService when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::RepositoryBackfillService).not_to receive(:new)

      subject.perform
    end

    it 'does not perform Geo::RepositoryBackfillService when can not obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { false }

      expect(Geo::RepositoryBackfillService).not_to receive(:new)

      subject.perform
    end
  end
end
