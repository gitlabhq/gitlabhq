require 'spec_helper'

describe ExternalIssue do
  let(:project) { double('project', to_reference: 'namespace1/project1') }
  let(:issue)   { described_class.new('EXT-1234', project) }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
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
