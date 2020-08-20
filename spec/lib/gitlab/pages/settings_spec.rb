# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::Settings do
  describe '#path' do
    subject { described_class.new(settings).path }

    let(:settings) { double(path: 'the path') }

    it { is_expected.to eq('the path') }

    it 'does not track calls' do
      expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

      subject
    end

    context 'when running under a web server' do
      before do
        allow(::Gitlab::Runtime).to receive(:web_server?).and_return(true)
      end

      it { is_expected.to eq('the path') }

      it 'does not track calls' do
        expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

        subject
      end

      context 'with the env var' do
        before do
          stub_env('GITLAB_PAGES_DENY_DISK_ACCESS', '1')
        end

        it { is_expected.to eq('the path') }

        it 'tracks a DiskAccessDenied exception' do
          expect(::Gitlab::ErrorTracking).to receive(:track_exception)
            .with(instance_of(described_class::DiskAccessDenied)).and_call_original

          subject
        end
      end
    end
  end
end
