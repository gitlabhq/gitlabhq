require 'spec_helper'

describe Geo::RepositoriesCleanUpWorker do
  let!(:geo_node)  { create(:geo_node) }
  let(:group)      { create(:group) }
  let!(:project_1) { create(:project, group: group) }
  let!(:project_2) { create(:project) }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    context 'when node has namespace restrictions' do
      it 'performs GeoRepositoryDestroyWorker for each project that do not belong to selected namespaces to replicate' do
        geo_node.update_attribute(:namespaces, [group])

        expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
          .with(project_2.id, project_2.name, project_2.full_path)
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
