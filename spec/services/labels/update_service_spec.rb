require 'spec_helper'

describe Labels::UpdateService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let!(:project1) { create(:empty_project, group: group) }

    let(:params) do
      {
        title: 'Security',
        color: '#d9534f',
        description: 'Security related stuff.'
      }
    end

    context 'with a group as subject' do
      let(:label) { create(:label, subject: group, title: 'Bug') }

      subject(:service) { described_class.new(group, double, params) }

      it 'updates the group label' do
        service.execute(label)

        expect(label).to have_attributes(params)
      end

      it 'updates the label from projects of the group' do
        project2 = create(:empty_project, group: group)
        create(:label, subject: project1, title: 'Bug')
        create(:label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(project1.labels.where(params)).not_to be_empty
        expect(project2.labels.where(params)).not_to be_empty
      end
    end

    context 'with a project as subject' do
      subject(:service) { described_class.new(project1, double, params) }

      it 'updates the project label' do
        label = create(:label, subject: project1)

        service.execute(label)

        expect(label).to have_attributes(params)
      end
    end
  end
end
