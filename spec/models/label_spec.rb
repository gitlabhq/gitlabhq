# == Schema Information
#
# Table name: labels
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  color      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  template   :boolean          default(FALSE)
#

require 'spec_helper'

describe Label do
  let(:label) { create(:label) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:label_links).dependent(:destroy) }
    it { is_expected.to have_many(:issues).through(:label_links).source(:target) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }

    it 'should validate color code' do
      expect(label).not_to allow_value('G-ITLAB').for(:color)
      expect(label).not_to allow_value('AABBCC').for(:color)
      expect(label).not_to allow_value('#AABBCCEE').for(:color)
      expect(label).not_to allow_value('GGHHII').for(:color)
      expect(label).not_to allow_value('#').for(:color)
      expect(label).not_to allow_value('').for(:color)

      expect(label).to allow_value('#AABBCC').for(:color)
      expect(label).to allow_value('#abcdef').for(:color)
    end

    it 'should validate title' do
      expect(label).not_to allow_value('G,ITLAB').for(:title)
      expect(label).not_to allow_value('G?ITLAB').for(:title)
      expect(label).not_to allow_value('G&ITLAB').for(:title)
      expect(label).not_to allow_value('').for(:title)

      expect(label).to allow_value('GITLAB').for(:title)
      expect(label).to allow_value('gitlab').for(:title)
      expect(label).to allow_value("customer's request").for(:title)
    end
  end

  describe '#to_reference' do
    context 'using id' do
      it 'returns a String reference to the object' do
        expect(label.to_reference).to eq "~#{label.id}"
        expect(label.to_reference(double('project'))).to eq "~#{label.id}"
      end
    end

    context 'using name' do
      it 'returns a String reference to the object' do
        expect(label.to_reference(:name)).to eq %(~"#{label.name}")
      end

      it 'uses id when name contains double quote' do
        label = create(:label, name: %q{"irony"})
        expect(label.to_reference(:name)).to eq "~#{label.id}"
      end
    end
  end
end
