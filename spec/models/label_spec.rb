require 'spec_helper'

describe Label do
  let(:label) { create(:label) }
  it { label.should be_valid }

  it { should belong_to(:project) }

  describe 'Validation' do
    it 'should validate color code' do
      build(:label, color: 'G-ITLAB').should_not be_valid
      build(:label, color: 'AABBCC').should_not be_valid
      build(:label, color: '#AABBCCEE').should_not be_valid
      build(:label, color: '#GGHHII').should_not be_valid
      build(:label, color: '#').should_not be_valid
      build(:label, color: '').should_not be_valid

      build(:label, color: '#AABBCC').should be_valid
    end

    it 'should validate title' do
      build(:label, title: 'G,ITLAB').should_not be_valid
      build(:label, title: 'G?ITLAB').should_not be_valid
      build(:label, title: 'G&ITLAB').should_not be_valid
      build(:label, title: '').should_not be_valid

      build(:label, title: 'GITLAB').should be_valid
      build(:label, title: 'gitlab').should be_valid
    end
  end
end
