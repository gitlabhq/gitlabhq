require 'spec_helper'

describe Labels::DestroyService, services: true do
  describe '#execute' do
    let!(:group) { create(:group) }
    let!(:project1) { create(:empty_project, group: group) }
    let!(:project2) { create(:empty_project, group: group) }

    context 'with a group label' do
      let!(:label) { create(:group_label, subject: group, title: 'Bug') }

      subject(:service) { described_class.new(group, double) }

      it 'removes the group label' do
        expect { service.execute(label) }.to change(group.labels, :count).by(-1)
      end

      it 'removes the label from all projects inside the group' do
        create(:group_label, subject: project1, title: 'Bug')
        create(:group_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(project1.labels.where(title: 'Bug')).to be_empty
        expect(project2.labels.where(title: 'Bug')).to be_empty
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, double) }

      it 'removes the project label' do
        label = create(:project_label, subject: project1)

        expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
      end

      context 'inherited from a group' do
        let!(:label) { create(:group_label, subject: project1, title: 'Bug') }

        it 'removes the group label' do
          create(:group_label, subject: group, title: 'Bug')

          expect { service.execute(label) }.to change(group.labels, :count).by(-1)
        end

        it 'removes the label from all projects inside the group' do
          create(:group_label, subject: project2, title: 'Bug')

          service.execute(label)

          expect(project2.labels.where(title: 'Bug')).to be_empty
        end

        it 'removes the project label' do
          expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
        end
      end
    end
  end
end
