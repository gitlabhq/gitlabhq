# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::ScanConfiguration do
  let_it_be(:project) { create(:project, :repository) }

  let(:scan) { described_class.new(project: project, type: type, configured: configured) }

  describe '#available?' do
    subject { scan.available? }

    let(:configured) { true }

    context 'with a core scanner' do
      let(:type) { :sast }

      it { is_expected.to be_truthy }
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

    context 'with a non configurable scaner' do
      let(:type) { :secret_detection }

      it { is_expected.to be_nil }
    end

    context 'with licensed scanner for FOSS environment' do
      let(:type) { :dast }

      before do
        stub_env('FOSS_ONLY', '1')
      end

      it { is_expected.to be_nil }
    end

    context 'with custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_nil }
    end
  end
end
