require 'spec_helper'

describe Labels::ToggleSubscriptionService, services: true do
  describe '#execute' do
    let(:user) { create(:user) }
    let!(:group) { create(:group) }
    let!(:project1) { create(:empty_project, group: group) }
    let!(:project2) { create(:empty_project, group: group) }

    context 'with a group label' do
      let(:label) { create(:group_label, subject: group, title: 'Bug') }

      subject(:service) { described_class.new(group, user) }

      it 'subscribes to group label' do
        service.execute(label)

        expect(label.subscribed?(user)).to eq true
      end

      it 'subscribes to labels from all projects inside the group' do
        label1 = create(:group_label, subject: project1, title: 'Bug')
        label2 = create(:group_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(label1.subscribed?(user)).to eq true
        expect(label2.subscribed?(user)).to eq true
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, user) }

      it 'subscribes to project label' do
        label = create(:project_label, subject: project1)

        service.execute(label)

        expect(label.subscribed?(user)).to eq true
      end

      context 'inherited from a group' do
        let(:label1) { create(:group_label, subject: project1, title: 'Bug') }

        it 'subscribes to group label' do
          label2 = create(:group_label, subject: group, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
        end

        it 'subscribes to labels from all projects inside the group' do
          label2 = create(:group_label, subject: project2, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
        end

        it 'subcribes to project label' do
          service.execute(label1)

          expect(label1.subscribed?(user)).to eq true
        end
      end
    end
  end
end
