# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::Settings do
  let(:settings) { double(path: 'the path', local_store: 'local store') }

  describe '#path' do
    subject { described_class.new(settings).path }

    it { is_expected.to eq('the path') }

    context 'when running under a web server outside of test mode' do
      before do
        allow(::Gitlab::Runtime).to receive(:test_suite?).and_return(false)
        allow(::Gitlab::Runtime).to receive(:puma?).and_return(true)
      end

      it 'logs a DiskAccessDenied error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(described_class::DiskAccessDenied)
        )

        subject
      end
    end

    context 'when local_store settings does not exist yet' do
      before do
        allow(Settings.pages).to receive(:local_store).and_return(nil)
      end

      it { is_expected.to eq('the path') }
    end

    context 'when local store exists but legacy storage is disabled' do
      before do
        allow(Settings.pages.local_store).to receive(:enabled).and_return(false)
      end

      it 'logs a DiskAccessDenied error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(described_class::DiskAccessDenied)
        )

        subject
      end
    end
  end
end
