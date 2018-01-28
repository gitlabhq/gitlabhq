require 'spec_helper'

describe Gitlab::LegacyGithubImport::IssuableFormatter do
  let(:raw_data) do
    double(number: 42)
  end
  let(:project) { double(import_type: 'github') }
  let(:issuable_formatter) { described_class.new(project, raw_data) }

  describe '#project_association' do
    it { expect { issuable_formatter.project_association }.to raise_error(NotImplementedError) }
  end

  describe '#number' do
    it { expect(issuable_formatter.number).to eq(42) }
  end

  describe '#find_condition' do
    it { expect(issuable_formatter.find_condition).to eq({ iid: 42 }) }
  end
end
