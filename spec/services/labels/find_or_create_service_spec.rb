require 'spec_helper'

describe Labels::FindOrCreateService do
  describe '#execute' do
    let(:group)   { create(:group) }
    let(:project) { create(:empty_project, namespace: group) }

    let(:params) do
      {
        title: 'Security',
        description: 'Security related stuff.',
        color: '#FF0000'
      }
    end

    context 'when acting on behalf of a specific user' do
      let(:user) { create(:user) }
      subject(:service) { described_class.new(user, project, params) }
      before do
        project.team << [user, :developer]
      end

      context 'when label does not exist at group level' do
        it 'creates a new label at project level' do
          expect { service.execute }.to change(project.labels, :count).by(1)
        end
      end

      context 'when label exists at group level' do
        it 'returns the group label' do
          group_label = create(:group_label, group: group, title: 'Security')

          expect(service.execute).to eq group_label
        end
      end

      context 'when label does not exist at group level' do
        it 'creates a new label at project leve' do
          expect { service.execute }.to change(project.labels, :count).by(1)
        end
      end

      context 'when label exists at project level' do
        it 'returns the project label' do
          project_label = create(:label, project: project, title: 'Security')

          expect(service.execute).to eq project_label
        end
      end
    end

    context 'when authorization is not required' do
      subject(:service) { described_class.new(nil, project, params) }

      it 'returns the project label' do
        project_label = create(:label, project: project, title: 'Security')

        expect(service.execute(skip_authorization: true)).to eq project_label
      end
    end
  end
end
