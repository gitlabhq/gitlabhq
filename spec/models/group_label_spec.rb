require 'spec_helper'

describe GroupLabel do
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
      let(:source_project) { build_stubbed(:project, name: 'project-1', namespace: namespace) }
      let(:target_project) { build_stubbed(:project, name: 'project-2', namespace: namespace) }

      it 'returns a String reference to the object' do
        expect(label.to_reference(source_project, target_project: target_project)).to eq %(project-1~#{label.id})
      end
    end

    context 'using invalid format' do
      it 'raises error' do
        expect { label.to_reference(format: :invalid) }
          .to raise_error StandardError, /Unknown format/
      end
    end
  end
end
