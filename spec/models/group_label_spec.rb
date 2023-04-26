# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLabel do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
  end

  describe '#subject' do
    it 'aliases group to subject' do
      subject = described_class.new(group: build(:group))

      expect(subject.subject).to be(subject.group)
    end
  end

  describe '#to_reference' do
    let(:label) { create(:group_label, title: 'feature') }

    context 'using id' do
      it 'returns a String reference to the object' do
        expect(label.to_reference).to eq "~#{label.id}"
      end
    end

    context 'using name' do
      it 'returns a String reference to the object' do
        expect(label.to_reference(format: :name)).to eq %(~"#{label.name}")
      end

      it 'uses id when name contains double quote' do
        label = create(:label, name: %q{"irony"})
        expect(label.to_reference(format: :name)).to eq "~#{label.id}"
      end
    end

    context 'cross-project' do
      let(:namespace) { build_stubbed(:namespace) }
      let(:source_project) { build_stubbed(:project, namespace: namespace) }
      let(:target_project) { build_stubbed(:project, namespace: namespace) }

      it 'returns a String reference to the object' do
        expect(label.to_reference(source_project, target_project: target_project)).to(
          eq("#{source_project.path}~#{label.id}")
        )
      end
    end

    context 'using invalid format' do
      it 'raises error' do
        expect { label.to_reference(format: :invalid) }
          .to raise_error StandardError, /Unknown format/
      end
    end
  end

  describe '#preloaded_parent_container' do
    let_it_be(:label) { create(:group_label) }

    before do
      label.reload # ensure associations are not loaded
    end

    context 'when group is loaded' do
      it 'does not invoke a DB query' do
        label.group

        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(0)
        expect(label.preloaded_parent_container).to eq(label.group)
      end
    end

    context 'when parent_container is loaded' do
      it 'does not invoke a DB query' do
        label.parent_container

        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(0)
        expect(label.preloaded_parent_container).to eq(label.parent_container)
      end
    end

    context 'when none of them are loaded' do
      it 'invokes a DB query' do
        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(1)
      end
    end
  end
end
