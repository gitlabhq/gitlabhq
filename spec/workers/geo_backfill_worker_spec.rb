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

    it 'performs GeoSingleRepositoryBackfillWorker for each project' do
      expect(GeoSingleRepositoryBackfillWorker).to receive(:new).twice.and_return(spy)

      subject.perform
    end

    it 'does not perform GeoSingleRepositoryBackfillWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(GeoSingleRepositoryBackfillWorker).not_to receive(:new)

      subject.perform
    end

    it 'does not perform GeoSingleRepositoryBackfillWorker for projects that repository exists' do
      create_list(:project, 2)

      expect(GeoSingleRepositoryBackfillWorker).to receive(:new).twice.and_return(spy)

      subject.perform
    end

    it 'does not perform GeoSingleRepositoryBackfillWorker when can not obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { false }

      expect(GeoSingleRepositoryBackfillWorker).not_to receive(:new)

      subject.perform
    end
  end
end
