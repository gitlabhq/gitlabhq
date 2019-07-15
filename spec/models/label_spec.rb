# frozen_string_literal: true

require 'spec_helper'

describe Label do
  describe 'modules' do
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Subscribable) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:issues).through(:label_links).source(:target) }
    it { is_expected.to have_many(:label_links).dependent(:destroy) }
    it { is_expected.to have_many(:lists).dependent(:destroy) }
    it { is_expected.to have_many(:priorities).class_name('LabelPriority') }
  end

  describe 'validation' do
    it { is_expected.to validate_uniqueness_of(:title).scoped_to([:group_id, :project_id]) }

    it 'validates color code' do
      is_expected.not_to allow_value('G-ITLAB').for(:color)
      is_expected.not_to allow_value('AABBCC').for(:color)
      is_expected.not_to allow_value('#AABBCCEE').for(:color)
      is_expected.not_to allow_value('GGHHII').for(:color)
      is_expected.not_to allow_value('#').for(:color)
      is_expected.not_to allow_value('').for(:color)

      is_expected.to allow_value('#AABBCC').for(:color)
      is_expected.to allow_value('#abcdef').for(:color)
    end

    it 'validates title' do
      is_expected.not_to allow_value('G,ITLAB').for(:title)
      is_expected.not_to allow_value('').for(:title)
      is_expected.not_to allow_value('s' * 256).for(:title)

      is_expected.to allow_value('GITLAB').for(:title)
      is_expected.to allow_value('gitlab').for(:title)
      is_expected.to allow_value('G?ITLAB').for(:title)
      is_expected.to allow_value('G&ITLAB').for(:title)
      is_expected.to allow_value("customer's request").for(:title)
      is_expected.to allow_value('s' * 255).for(:title)
    end
  end

  describe '#color' do
    it 'strips color' do
      label = described_class.new(color: '   #abcdef   ')
      label.valid?

      expect(label.color).to eq('#abcdef')
    end

    it 'uses default color if color is missing' do
      label = described_class.new(color: nil)

      expect(label.color).to be(Label::DEFAULT_COLOR)
    end
  end

  describe '#text_color' do
    it 'uses default color if color is missing' do
      expect(LabelsHelper).to receive(:text_color_for_bg).with(Label::DEFAULT_COLOR)
        .and_return(spy)

      label = described_class.new(color: nil)

      label.text_color
    end
  end

  describe '#title' do
    it 'sanitizes title' do
      label = described_class.new(title: '<b>foo & bar?</b>')
      expect(label.title).to eq('foo & bar?')
    end

    it 'strips title' do
      label = described_class.new(title: '   label   ')
      label.valid?

      expect(label.title).to eq('label')
    end
  end

  describe '#description' do
    it 'sanitizes description' do
      label = described_class.new(description: '<b>foo & bar?</b>')
      expect(label.description).to eq('foo & bar?')
    end
  end

  describe 'priorization' do
    subject(:label) { create(:label) }

    let(:project) { label.project }

    describe '#prioritize!' do
      context 'when label is not prioritized' do
        it 'creates a label priority' do
          expect { label.prioritize!(project, 1) }.to change(label.priorities, :count).by(1)
        end

        it 'sets label priority' do
          label.prioritize!(project, 1)

          expect(label.priorities.first.priority).to eq 1
        end
      end

      context 'when label is prioritized' do
        let!(:priority) { create(:label_priority, project: project, label: label, priority: 0) }

        it 'does not create a label priority' do
          expect { label.prioritize!(project, 1) }.not_to change(label.priorities, :count)
        end

        it 'updates label priority' do
          label.prioritize!(project, 1)

          expect(priority.reload.priority).to eq 1
        end
      end
    end

    describe '#unprioritize!' do
      it 'removes label priority' do
        create(:label_priority, project: project, label: label, priority: 0)

        expect { label.unprioritize!(project) }.to change(label.priorities, :count).by(-1)
      end
    end

    describe '#priority' do
      context 'when label is not prioritized' do
        it 'returns nil' do
          expect(label.priority(project)).to be_nil
        end
      end

      context 'when label is prioritized' do
        it 'returns label priority' do
          create(:label_priority, project: project, label: label, priority: 1)

          expect(label.priority(project)).to eq 1
        end
      end
    end
  end

  describe '.search' do
    let(:label) { create(:label, title: 'bug', description: 'incorrect behavior') }

    it 'returns labels with a partially matching title' do
      expect(described_class.search(label.title[0..2])).to eq([label])
    end

    it 'returns labels with a partially matching description' do
      expect(described_class.search(label.description[0..5])).to eq([label])
    end

    it 'returns nothing' do
      expect(described_class.search('feature')).to be_empty
    end
  end

  describe '.subscribed_by' do
    let!(:user)   { create(:user) }
    let!(:label)  { create(:label) }
    let!(:label2) { create(:label) }

    before do
      label.subscribe(user)
    end

    it 'returns subscribed labels' do
      expect(described_class.subscribed_by(user.id)).to eq([label])
    end

    it 'returns nothing' do
      expect(described_class.subscribed_by(0)).to be_empty
    end
  end

  describe '.optionally_subscribed_by' do
    let!(:user)   { create(:user) }
    let!(:label)  { create(:label) }
    let!(:label2) { create(:label) }

    before do
      label.subscribe(user)
    end

    it 'returns subscribed labels' do
      expect(described_class.optionally_subscribed_by(user.id)).to eq([label])
    end

    it 'returns all labels if user_id is nil' do
      expect(described_class.optionally_subscribed_by(nil)).to match_array([label, label2])
    end
  end
end
