require 'spec_helper'

describe ExternalIssue, models: true do
  let(:project) { double('project', to_reference: 'namespace1/project1') }
  let(:issue)   { described_class.new('EXT-1234', project) }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe '.reference_pattern' do
    it 'allows underscores in the project name' do
      expect(ExternalIssue.reference_pattern.match('EXT_EXT-1234')[0]).to eq 'EXT_EXT-1234'
    end

    it 'allows numbers in the project name' do
      expect(ExternalIssue.reference_pattern.match('EXT3_EXT-1234')[0]).to eq 'EXT3_EXT-1234'
    end

    it 'requires the project name to begin with A-Z' do
      expect(ExternalIssue.reference_pattern.match('3EXT_EXT-1234')).to eq nil
      expect(ExternalIssue.reference_pattern.match('EXT_EXT-1234')[0]).to eq 'EXT_EXT-1234'
    end
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(issue.to_reference).to eq issue.id
    end
  end

  describe '#title' do
    it 'returns a title' do
      expect(issue.title).to eq "External Issue #{issue}"
    end
  end
end
