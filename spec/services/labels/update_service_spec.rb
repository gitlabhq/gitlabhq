require 'spec_helper'

describe Labels::UpdateService, services: true do
  describe '#execute' do
    let!(:group) { create(:group) }
    let!(:project1) { create(:empty_project, group: group) }
    let!(:project2) { create(:empty_project, group: group) }

    let(:params) do
      {
        title: 'Security',
        color: '#d9534f',
        description: 'Security related stuff.'
      }
    end

    context 'with a group label' do
      let(:label) { create(:label, subject: group, title: 'Bug') }

      subject(:service) { described_class.new(group, double, params) }

      it 'updates the group label' do
        service.execute(label)

        expect(label).to have_attributes(params)
      end

      it 'updates the label of all projects inside the group' do
        label1 = create(:group_label, subject: project1, title: 'Bug')
        label2 = create(:group_label, subject: project2, title: 'Bug')

        service.execute(label1)

        expect(label1.reload).to have_attributes(params)
        expect(label2.reload).to have_attributes(params)
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, double, params) }

      it 'updates the project label' do
        label = create(:project_label, subject: project1)

        service.execute(label)

        expect(label).to have_attributes(params)
      end

      context 'inherited from a group' do
        it 'updates the group label' do
          label1 = create(:group_label, subject: group, title: 'Bug')
          label2 = create(:group_label, subject: project1, title: 'Bug')

          service.execute(label2)

          expect(label1.reload).to have_attributes(params)
        end

        it 'updates the label of all projects inside the group' do
          label1 = create(:group_label, subject: project1, title: 'Bug')
          label2 = create(:group_label, subject: project2, title: 'Bug')

          service.execute(label1)

          expect(label1.reload).to have_attributes(params)
          expect(label2.reload).to have_attributes(params)
        end

        it 'updates the project label' do
          label = create(:group_label, subject: project1)

          service.execute(label)

          expect(label).to have_attributes(params)
        end
      end
    end
  end
end
