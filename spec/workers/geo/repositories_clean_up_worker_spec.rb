require 'spec_helper'

describe Geo::RepositoriesCleanUpWorker do
  let!(:geo_node) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    context 'when node has namespace restrictions' do
      it 'performs GeoRepositoryDestroyWorker for each project that does not belong to selected namespaces to replicate' do
        geo_node.update_attribute(:namespaces, [synced_group])

        expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
          .with(unsynced_project.id, unsynced_project.name, unsynced_project.full_path)
          .once.and_return(1)

        subject.perform(geo_node.id)
      end
    end

    context 'when does not node have namespace restrictions' do
      it 'does not perform GeoRepositoryDestroyWorker' do
        expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

        subject.perform(geo_node.id)
      end
    end

    context 'when cannnot obtain a lease' do
      it 'does not perform GeoRepositoryDestroyWorker' do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { false }

        expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

        subject.perform(geo_node.id)
      end
    end

    context 'when Geo node could not be found' do
      it 'does not raise an error' do
        expect { subject.perform(-1) }.not_to raise_error
      end
    end
  end
end
