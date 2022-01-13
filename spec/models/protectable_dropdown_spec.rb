# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectableDropdown do
  subject(:dropdown) { described_class.new(project, ref_type) }

  let(:project) { create(:project, :repository) }

  describe 'initialize' do
    it 'raises ArgumentError for invalid ref type' do
      expect { described_class.new(double, :foo) }
        .to raise_error(ArgumentError, "invalid ref type `foo`")
    end
  end

  shared_examples 'protectable_ref_names' do
    context 'when project repository is not empty' do
      it 'includes elements matching a protected ref wildcard' do
        is_expected.to include(matching_ref)

        factory = ref_type == :branches ? :protected_branch : :protected_tag

        create(factory, name: "#{matching_ref[0]}*", project: project)

        subject = described_class.new(project.reload, ref_type)

        expect(subject.protectable_ref_names).to include(matching_ref)
      end
    end

    context 'when project repository is empty' do
      let(:project) { create(:project) }

      it 'returns empty list' do
        is_expected.to be_empty
      end
    end
  end

  describe '#protectable_ref_names' do
    subject { dropdown.protectable_ref_names }

    context 'for branches' do
      let(:ref_type) { :branches }
      let(:matching_ref) { 'feature' }

      before do
        create(:protected_branch, project: project, name: 'master')
      end

      it { is_expected.to include(matching_ref) }
      it { is_expected.not_to include('master') }

      it_behaves_like 'protectable_ref_names'
    end

    context 'for tags' do
      let(:ref_type) { :tags }
      let(:matching_ref) { 'v1.0.0' }

      before do
        create(:protected_tag, project: project, name: 'v1.1.0')
      end

      it { is_expected.to include(matching_ref) }
      it { is_expected.not_to include('v1.1.0') }

      it_behaves_like 'protectable_ref_names'
    end
  end

  describe '#hash' do
    subject { dropdown.hash }

    context 'for branches' do
      let(:ref_type) { :branches }

      it { is_expected.to include(id: 'feature', text: 'feature', title: 'feature') }
    end

    context 'for tags' do
      let(:ref_type) { :tags }

      it { is_expected.to include(id: 'v1.0.0', text: 'v1.0.0', title: 'v1.0.0') }
    end
  end
end
