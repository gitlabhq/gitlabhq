# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::ScanConfiguration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }

  let(:scan) { described_class.new(project: project, type: type, configured: configured) }

  describe '#available?' do
    subject { scan.available? }

    let(:configured) { true }

    context 'with a core scanner' do
      where(type: %i(sast sast_iac secret_detection container_scanning))

      with_them do
        it { is_expected.to be_truthy }
      end
    end

    context 'with custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_falsey }
    end
  end

  describe '#configured?' do
    subject { scan.configured? }

    let(:type) { :sast }
    let(:configured) { false }

    it { is_expected.to be_falsey }
  end

  describe '#configuration_path' do
    subject { scan.configuration_path }

    let(:configured) { true }
    let(:type) { :sast }

    it { is_expected.to be_nil }
  end

  describe '#meta_info_path' do
    subject { scan.meta_info_path }

    let(:configured) { true }
    let(:available) { true }
    let(:type) { :dast }

    it { is_expected.to be_nil }
  end

  describe '#can_enable_by_merge_request?' do
    subject { scan.can_enable_by_merge_request? }

    let(:configured) { true }

    context 'with a core scanner' do
      where(type: %i(sast sast_iac secret_detection))

      with_them do
        it { is_expected.to be_truthy }
      end
    end

    context 'with a custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_falsey }
    end
  end
end
