require 'spec_helper'

describe Labels::CreateService, services: true do
  describe '#execute' do
    let!(:group) { create(:group) }
    let!(:project) { create(:empty_project, group: group) }

    let(:params) do
      {
        title: 'Security',
        color: '#5CB85C',
        description: 'Security related stuff.'
      }
    end

    context 'with a global label' do
      subject(:service) { described_class.new(nil, double, params.merge(label_type: :global_label)) }

      it 'creates the global label' do
        expect { service.execute }.to change(Label.where(subject: nil, label_type: Label.label_types[:global_label]), :count).by(1)
      end

      it 'sets label_type to global_label' do
        service.execute

        expect(Label.last).to have_attributes(label_type: 'global_label')
      end

      it 'becames available to all already existing groups' do
        service.execute

        expect(Label.where(params.merge(subject: group, label_type: Label.label_types[:global_label]))).not_to be_empty
      end

      it 'becames available to all already existing projects' do
        service.execute

        expect(project.labels.where(params.merge(label_type: Label.label_types[:global_label]))).not_to be_empty
      end

      it 'does not overwrite label that already exists in a group' do
        params = { title: 'Security', color: '#FF0000', description: 'Sample', label_type: Label.label_types[:group_label] }
        group.labels.create(params)

        service.execute

        expect(group.labels.where(params)).not_to be_empty
      end

      it 'does not overwrite label that already exists in a project' do
        params = { title: 'Security', color: '#FF0000', description: 'Sample', label_type: Label.label_types[:project_label] }
        project.labels.create(params)

        service.execute

        expect(project.labels.where(params)).not_to be_empty
      end
    end

    context 'with a group label' do
      subject(:service) { described_class.new(group, double, params.merge(label_type: :group_label)) }

      it 'creates the group label' do
        expect { service.execute }.to change(group.labels, :count).by(1)
      end

      it 'sets label_type to group_label' do
        service.execute

        expect(Label.last).to have_attributes(label_type: 'group_label')
      end

      it 'becames available to all already existing projects of the group' do
        service.execute

        expect(project.labels.where(params.merge(label_type: Label.label_types[:group_label]))).not_to be_empty
      end

      it 'does not create a label that already exists on the global level' do
        Label.create(params.merge(label_type: Label.label_types[:global_label]))

        expect { service.execute }.not_to change(group.labels, :count)
      end

      it 'does not overwrite label that already exists in the project' do
        params = { title: 'Security', color: '#FF0000', description: 'Sample', label_type: Label.label_types[:project_label] }
        project.labels.create(params)

        service.execute

        expect(project.labels.where(params)).not_to be_empty
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project, double, params.merge(label_type: :project_label)) }

      it 'creates the project label' do
        expect { service.execute }.to change(project.labels, :count).by(1)
      end

      it 'sets label_type to project_label' do
        service.execute

        expect(Label.last).to have_attributes(label_type: 'project_label')
      end

      it 'does not create a label that already exists on the global level' do
        Label.create(params.merge(label_type: Label.label_types[:global_label]))

        expect { service.execute }.not_to change(project.labels, :count)
      end

      it 'does not create a label that already exists on the group level' do
        group.labels.create(params.merge(label_type: Label.label_types[:group_label]))

        expect { service.execute }.not_to change(project.labels, :count)
      end
    end
  end
end
