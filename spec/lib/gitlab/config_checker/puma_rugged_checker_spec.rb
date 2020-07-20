# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ConfigChecker::PumaRuggedChecker do
  describe '#check' do
    subject { described_class.check }

    context 'application is not puma' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(false)
      end

      it { is_expected.to be_empty }
    end

    context 'application is puma' do
      let(:notice_multi_threaded_puma_with_rugged) do
        {
            type: 'warning',
            message: 'Puma is running with a thread count above 1 and the Rugged '\
                     'service is enabled. This may decrease performance in some environments. '\
                     'See our <a href="https://docs.gitlab.com/ee/administration/operations/puma.html#performance-caveat-when-using-puma-with-rugged">documentation</a> '\
                     'for details of this issue.'
        }
      end

      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
        allow(described_class).to receive(:running_puma_with_multiple_threads?).and_return(multithreaded_puma)
        allow(described_class).to receive(:rugged_enabled_through_feature_flag?).and_return(rugged_enabled)
      end

      context 'not multithreaded_puma and rugged API enabled' do
        let(:multithreaded_puma) { false }
        let(:rugged_enabled) { true }

        it { is_expected.to be_empty }
      end

      context 'not multithreaded_puma and rugged API is not enabled' do
        let(:multithreaded_puma) { false }
        let(:rugged_enabled) { false }

        it { is_expected.to be_empty }
      end

      context 'multithreaded_puma and rugged API is not enabled' do
        let(:multithreaded_puma) { true }
        let(:rugged_enabled) { false }

        it { is_expected.to be_empty }
      end

      context 'multithreaded_puma and rugged API is enabled' do
        let(:multithreaded_puma) { true }
        let(:rugged_enabled) { true }

        it 'report multi_threaded_puma_with_rugged notices' do
          is_expected.to contain_exactly(notice_multi_threaded_puma_with_rugged)
        end
      end
    end
  end
end
