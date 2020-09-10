# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::Settings do
  describe '#path' do
    subject { described_class.new(settings).path }

    let(:settings) { double(path: 'the path') }

    it { is_expected.to eq('the path') }

    context 'when running under a web server' do
      before do
        allow(::Gitlab::Runtime).to receive(:web_server?).and_return(true)
      end

      it { is_expected.to eq('the path') }

      context 'with the env var' do
        before do
          stub_env('GITLAB_PAGES_DENY_DISK_ACCESS', '1')
        end

        it 'raises a DiskAccessDenied exception' do
          expect { subject }.to raise_error(described_class::DiskAccessDenied)
        end
      end
    end
  end
end
