require 'spec_helper'

describe Labels::UpdateService, services: true do
  describe '#execute' do
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:project1) { create(:empty_project, group: group1) }
    let!(:project2) { create(:empty_project, group: group1) }

    let(:params) do
      {
        title: 'Security',
        color: '#d9534f',
        description: 'Security related stuff.'
      }
    end

    context 'with a global label' do
      let(:label) { create(:global_label, title: 'Bug') }

      subject(:service) { described_class.new(nil, double, params) }

      it 'updates the global label' do
        service.execute(label)

        expect(label).to have_attributes(params)
      end

      it 'updates the label of all groups that have the label' do
        label1 = create(:global_label, subject: group1, title: 'Bug')
        label2 = create(:global_label, subject: group2, title: 'Bug')

        service.execute(label)

        expect(label1.reload).to have_attributes(params)
        expect(label2.reload).to have_attributes(params)
      end

      it 'updates the label of all projects that have the label' do
        label1 = create(:global_label, subject: project1, title: 'Bug')
        label2 = create(:global_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(label1.reload).to have_attributes(params)
        expect(label2.reload).to have_attributes(params)
      end
    end

    context 'with a group label' do
      let(:label) { create(:group_label, subject: group1, title: 'Bug') }

      subject(:service) { described_class.new(group1, double, params) }

      it 'updates the group label' do
        service.execute(label)

        expect(label).to have_attributes(params)
      end

      it 'updates the label of all projects inside the group that have the label' do
        label1 = create(:group_label, subject: project1, title: 'Bug')
        label2 = create(:group_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(label1.reload).to have_attributes(params)
        expect(label2.reload).to have_attributes(params)
      end

      context 'inherited from a global label' do
        it 'updates the global label' do
          label1 = create(:global_label, title: 'Bug')
          label2 = create(:global_label, subject: group1, title: 'Bug')

          service.execute(label2)

          expect(label1.reload).to have_attributes(params)
        end

        it 'updates the group label' do
          label = create(:group_label, subject: group1, title: 'Bug')

          service.execute(label)

          expect(label.reload).to have_attributes(params)
        end

        it 'updates the label of all groups that have the label' do
          label1 = create(:global_label, subject: group1, title: 'Bug')
          label2 = create(:global_label, subject: group2, title: 'Bug')

          service.execute(label1)

          expect(label2.reload).to have_attributes(params)
        end

        it 'updates the label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: project2, title: 'Bug')
          label3 = create(:global_label, subject: project3, title: 'Bug')

          service.execute(label1)

          expect(label2.reload).to have_attributes(params)
          expect(label3.reload).to have_attributes(params)
        end
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, double, params) }

      it 'updates the project label' do
        label = create(:project_label, subject: project1)

        service.execute(label)

        expect(label).to have_attributes(params)
      end

      context 'inherited from a global label' do
        it 'updates the global label' do
          label1 = create(:global_label, title: 'Bug')
          label2 = create(:global_label, subject: project1, title: 'Bug')

          service.execute(label2)

          expect(label1.reload).to have_attributes(params)
        end

        it 'updates the project label' do
          label = create(:global_label, subject: project1, title: 'Bug')

          service.execute(label)

          expect(label.reload).to have_attributes(params)
        end

        it 'updates the label of all groups that have the label' do
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: group1, title: 'Bug')
          label3 = create(:global_label, subject: group2, title: 'Bug')

          service.execute(label1)

          expect(label2.reload).to have_attributes(params)
          expect(label3.reload).to have_attributes(params)
        end

        it 'updates the label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: project2, title: 'Bug')
          label3 = create(:global_label, subject: project3, title: 'Bug')

          service.execute(label1)

          expect(label2.reload).to have_attributes(params)
          expect(label3.reload).to have_attributes(params)
        end
      end

      context 'inherited from a group label' do
        it 'updates the group label' do
          label1 = create(:group_label, subject: group1, title: 'Bug')
          label2 = create(:group_label, subject: project1, title: 'Bug')

          service.execute(label2)

          expect(label1.reload).to have_attributes(params)
        end

        it 'updates the project label' do
          label = create(:group_label, subject: project1)

          service.execute(label)

          expect(label).to have_attributes(params)
        end

        it 'updates the label of all projects inside the group that have the label' do
          label1 = create(:group_label, subject: project1, title: 'Bug')
          label2 = create(:group_label, subject: project2, title: 'Bug')

          service.execute(label1)

          expect(label2.reload).to have_attributes(params)
        end
      end
    end
  end
end
