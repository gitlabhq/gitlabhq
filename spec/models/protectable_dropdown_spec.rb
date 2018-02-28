require 'spec_helper'

describe ProtectableDropdown do
  let(:project) { create(:project, :repository) }
  let(:subject) { described_class.new(project, :branches) }

  describe 'initialize' do
    it 'raises ArgumentError for invalid ref type' do
      expect { described_class.new(double, :foo) }
        .to raise_error(ArgumentError, "invalid ref type `foo`")
    end
  end

  describe '#protectable_ref_names' do
    before do
      project.protected_branches.create(name: 'master')
    end

    it { expect(subject.protectable_ref_names).to include('feature') }
    it { expect(subject.protectable_ref_names).not_to include('master') }

    it "includes branches matching a protected branch wildcard" do
      expect(subject.protectable_ref_names).to include('feature')

      create(:protected_branch, name: 'feat*', project: project)

      subject = described_class.new(project.reload, :branches)

      expect(subject.protectable_ref_names).to include('feature')
    end
  end
end
