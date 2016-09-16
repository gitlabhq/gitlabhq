require 'spec_helper'

describe Labels::DestroyService, services: true do
  describe '#execute' do
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:project1) { create(:empty_project, group: group1) }
    let!(:project2) { create(:empty_project, group: group1) }

    context 'with a global label' do
      let!(:label) { create(:global_label, title: 'Bug') }

      subject(:service) { described_class.new(nil, double) }

      it 'removes the global label' do
        expect { service.execute(label) }.to change(Label.where(subject: nil, label_type: Label.label_types[:global_label]), :count).by(-1)
      end

      it 'removes the label of all groups that have the label' do
        create(:global_label, subject: group1, title: 'Bug')
        create(:global_label, subject: group2, title: 'Bug')

        service.execute(label)

        expect(group1.reload.labels).to be_empty
        expect(group2.reload.labels).to be_empty
      end

      it 'removes the label of all projects that have the label' do
        create(:global_label, subject: project1, title: 'Bug')
        create(:global_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(project1.reload.labels).to be_empty
        expect(project2.reload.labels).to be_empty
      end
    end

    context 'with a group label' do
      let!(:label) { create(:group_label, subject: group1, title: 'Bug') }

      subject(:service) { described_class.new(group1, double) }

      it 'removes the group label' do
        expect { service.execute(label) }.to change(group1.labels, :count).by(-1)
      end

      it 'removes the label from all projects inside the group that have the label' do
        create(:group_label, subject: project1, title: 'Bug')
        create(:group_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(project1.labels.where(title: 'Bug')).to be_empty
        expect(project2.labels.where(title: 'Bug')).to be_empty
      end

      context 'inherited from a global label' do
        let!(:label) { create(:global_label, subject: group1, title: 'Bug') }

        it 'removes the global label' do
          create(:global_label, subject: nil, title: 'Bug')

          expect { service.execute(label) }.to change(Label.where(subject: nil, label_type: Label.label_types[:global_label]), :count).by(-1)
        end

        it 'removes the group label' do
          create(:global_label, subject: nil, title: 'Bug')

          expect { service.execute(label) }.to change(group1.labels, :count).by(-1)
        end

        it 'removes the label of all groups that have the label' do
          create(:global_label, subject: group2, title: 'Bug')

          expect { service.execute(label) }.to change(group2.labels, :count).by(-1)
        end

        it 'removes the label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          create(:global_label, subject: project1, title: 'Bug')
          create(:global_label, subject: project2, title: 'Bug')
          create(:global_label, subject: project3, title: 'Bug')

          service.execute(label)

          expect(project1.reload.labels).to be_empty
          expect(project2.reload.labels).to be_empty
          expect(project3.reload.labels).to be_empty
        end
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, double) }

      it 'removes the project label' do
        label = create(:project_label, subject: project1)

        expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
      end

      context 'inherited from a global label' do
        let!(:label) { create(:global_label, subject: project1, title: 'Bug') }

        it 'removes the global label' do
          create(:global_label, subject: nil, title: 'Bug')

          expect { service.execute(label) }.to change(Label.where(subject: nil, label_type: Label.label_types[:global_label]), :count).by(-1)
        end

        it 'removes the project label' do
          expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
        end

        it 'removes the label of all groups that have the label' do
          create(:global_label, subject: group1, title: 'Bug')
          create(:global_label, subject: group2, title: 'Bug')

          service.execute(label)

          expect(group1.reload.labels).to be_empty
          expect(group2.reload.labels).to be_empty
        end

        it 'removes the label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          create(:global_label, subject: project2, title: 'Bug')
          create(:global_label, subject: project3, title: 'Bug')

          service.execute(label)

          expect(project2.reload.labels).to be_empty
          expect(project3.reload.labels).to be_empty
        end
      end

      context 'inherited from a group' do
        let!(:label) { create(:group_label, subject: project1, title: 'Bug') }

        it 'removes the group label' do
          create(:group_label, subject: group1, title: 'Bug')

          expect { service.execute(label) }.to change(group1.labels, :count).by(-1)
        end

        it 'removes the project label' do
          expect { service.execute(label) }.to change(project1.labels, :count).by(-1)
        end

        it 'removes the label from all projects inside the group that have the label' do
          create(:group_label, subject: project2, title: 'Bug')

          service.execute(label)

          expect(project2.labels.where(title: 'Bug')).to be_empty
        end
      end
    end
  end
end
