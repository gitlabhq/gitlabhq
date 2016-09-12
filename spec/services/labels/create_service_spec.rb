require 'spec_helper'

describe Labels::CreateService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let!(:project) { create(:empty_project, group: group) }

    let(:params) do
      {
        title: 'Security',
        color: '#5CB85C',
        description: 'Security related stuff.'
      }
    end

    context 'with a group as subject' do
      subject(:service) { described_class.new(group, double, params) }

      it 'creates a label' do
        expect { service.execute }.to change(group.labels, :count).by(1)
      end

      it 'becames available to all already existing projects of the group' do
        service.execute

        expect(project.labels.where(params)).not_to be_empty
      end

      it 'does not overwrite label that already exists in the project' do
        params = { title: 'Security', color: '#FF0000', description: 'Sample' }
        project.labels.create(params)

        service.execute

        expect(project.labels.where(params)).not_to be_empty
      end
    end

    context 'with a project as subject' do
      subject(:service) { described_class.new(project, double, params) }

      it 'creates a label' do
        expect { service.execute }.to change(project.labels, :count).by(1)
      end

      it 'does not create a label that already exists on the group level' do
        group.labels.create(params)

        expect { service.execute }.not_to change(project.labels, :count)
      end
    end
  end
end
