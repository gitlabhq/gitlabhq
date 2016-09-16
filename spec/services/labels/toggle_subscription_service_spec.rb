require 'spec_helper'

describe Labels::ToggleSubscriptionService, services: true do
  describe '#execute' do
    let(:user) { create(:user) }
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:project1) { create(:empty_project, group: group1) }
    let!(:project2) { create(:empty_project, group: group1) }

    it 'delegates the subscription management to Label#toggle_subscription' do
      label = create(:label, subject: project1)

      expect(label).to receive(:toggle_subscription).once

      described_class.new(project1, user).execute(label)
    end

    context 'with a global label' do
      let(:label) { create(:global_label, title: 'Bug') }

      subject(:service) { described_class.new(nil, user) }

      it 'subscribes to global label' do
        service.execute(label)

        expect(label.subscribed?(user)).to eq true
      end

      it 'subscribes to labels of all groups that have the label' do
        label1 = create(:global_label, subject: group1, title: 'Bug')
        label2 = create(:global_label, subject: group2, title: 'Bug')

        service.execute(label)

        expect(label1.subscribed?(user)).to eq true
        expect(label2.subscribed?(user)).to eq true
      end

      it 'subscribes to label of all projects that have the label' do
        label1 = create(:global_label, subject: project1, title: 'Bug')
        label2 = create(:global_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(label1.subscribed?(user)).to eq true
        expect(label2.subscribed?(user)).to eq true
      end
    end

    context 'with a group label' do
      let(:label) { create(:group_label, subject: group1, title: 'Bug') }

      subject(:service) { described_class.new(group1, user) }

      it 'subscribes to group label' do
        service.execute(label)

        expect(label.subscribed?(user)).to eq true
      end

      it 'subscribes to labels from all projects inside the group that have the label' do
        label1 = create(:group_label, subject: project1, title: 'Bug')
        label2 = create(:group_label, subject: project2, title: 'Bug')

        service.execute(label)

        expect(label1.subscribed?(user)).to eq true
        expect(label2.subscribed?(user)).to eq true
      end

      context 'inherited from a global label' do
        it 'subscribes to global label' do
          label1 = create(:global_label, title: 'Bug')
          label2 = create(:global_label, subject: group1, title: 'Bug')

          service.execute(label2)

          expect(label1.subscribed?(user)).to eq true
        end

        it 'subscribes to group label' do
          label = create(:group_label, subject: group1, title: 'Bug')

          service.execute(label)

          expect(label.subscribed?(user)).to eq true
        end

        it 'subscribes to label of all groups that have the label' do
          label1 = create(:global_label, subject: group1, title: 'Bug')
          label2 = create(:global_label, subject: group2, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
        end

        it 'subscribes to label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: project2, title: 'Bug')
          label3 = create(:global_label, subject: project3, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
          expect(label3.subscribed?(user)).to eq true
        end
      end
    end

    context 'with a project label' do
      subject(:service) { described_class.new(project1, user) }

      it 'subscribes to project label' do
        label = create(:project_label, subject: project1)

        service.execute(label)

        expect(label.subscribed?(user)).to eq true
      end

      context 'inherited from a global label' do
        it 'subscribes to global label' do
          label1 = create(:global_label, title: 'Bug')
          label2 = create(:global_label, subject: project1, title: 'Bug')

          service.execute(label2)

          expect(label1.subscribed?(user)).to eq true
        end

        it 'subscribes to project label' do
          label = create(:global_label, subject: project1, title: 'Bug')

          service.execute(label)

          expect(label.subscribed?(user)).to eq true
        end

        it 'subscribes to label of all groups that have the label' do
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: group1, title: 'Bug')
          label3 = create(:global_label, subject: group2, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
          expect(label3.subscribed?(user)).to eq true
        end

        it 'subscribes to label of all projects that have the label' do
          project3 = create(:empty_project, group: group2)
          label1 = create(:global_label, subject: project1, title: 'Bug')
          label2 = create(:global_label, subject: project2, title: 'Bug')
          label3 = create(:global_label, subject: project3, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
          expect(label3.subscribed?(user)).to eq true
        end
      end

      context 'inherited from a group' do
        let(:label1) { create(:group_label, subject: project1, title: 'Bug') }

        it 'subscribes to group label' do
          label2 = create(:group_label, subject: group1, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
        end

        it 'subcribes to project label' do
          service.execute(label1)

          expect(label1.subscribed?(user)).to eq true
        end

        it 'subscribes to labels from all projects inside the group that have the label' do
          label2 = create(:group_label, subject: project2, title: 'Bug')

          service.execute(label1)

          expect(label2.subscribed?(user)).to eq true
        end
      end
    end
  end
end
