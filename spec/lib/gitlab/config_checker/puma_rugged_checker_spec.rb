# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ConfigChecker::PumaRuggedChecker do
  describe '#check' do
    subject { described_class.check }

    context 'application is not puma' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(false)
      end

      it { is_expected.to be_empty }
    end

    context 'application is puma' do
      let(:notice_running_puma) do
        {
            type: 'info',
            message: 'You are running Puma, which is currently experimental. '\
                     'More information is available in our '\
                     '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html">documentation</a>.'
        }
      end
      let(:notice_multi_threaded_puma) do
        {
            type: 'info',
            message: 'Puma is running with a thread count above 1. '\
                     'Information on deprecated GitLab features in this configuration is available in the '\
                     '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html">documentation</a>.'\
        }
      end
      let(:notice_multi_threaded_puma_with_rugged) do
        {
            type: 'warning',
            message: 'Puma is running with a thread count above 1 and the rugged '\
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

        it 'report running puma notice' do
          is_expected.to contain_exactly(notice_running_puma)
        end
      end

      context 'not multithreaded_puma and rugged API is not enabled' do
        let(:multithreaded_puma) { false }
        let(:rugged_enabled) { false }

        it 'report running puma notice' do
          is_expected.to contain_exactly(notice_running_puma)
        end
      end

      context 'multithreaded_puma and rugged API is not enabled' do
        let(:multithreaded_puma) { true }
        let(:rugged_enabled) { false }

        it 'report running puma notice and multi-thread puma notice' do
          is_expected.to contain_exactly(notice_running_puma, notice_multi_threaded_puma)
        end
      end

      context 'multithreaded_puma and rugged API is enabled' do
        let(:multithreaded_puma) { true }
        let(:rugged_enabled) { true }

        it 'report puma/multi_threaded_puma/multi_threaded_puma_with_rugged notices' do
          is_expected.to contain_exactly(notice_running_puma, notice_multi_threaded_puma, notice_multi_threaded_puma_with_rugged)
        end
      end
    end
  end
end
