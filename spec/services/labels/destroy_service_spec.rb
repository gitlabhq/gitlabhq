require 'spec_helper'

describe Labels::DestroyService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let!(:project1) { create(:empty_project, group: group) }

    context 'with a group as subject' do
      let!(:label) { create(:label, subject: group, title: 'Bug') }

      subject(:service) { described_class.new(group, double) }

      it 'removes the label' do
        expect { service.execute(label) }.to change(group.labels, :count).by(-1)
      end

      it 'removes the label from projects of the group' do
        project2 = create(:empty_project, group: group)
        create(:label, subject: project1, title: 'Bug')
        create(:label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(project1.labels.where(title: 'Bug')).to be_empty
        expect(project2.labels.where(title: 'Bug')).to be_empty
      end
    end

    context 'with a project as subject' do
      subject(:service) { described_class.new(project1, double) }

      it 'removes the label' do
        label = create(:label, subject: project1)

        expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
      end
    end
  end
end
