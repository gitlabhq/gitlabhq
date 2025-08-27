# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Metadatable, feature_category: :continuous_integration do
  let_it_be_with_refind(:processable) { create(:ci_processable, options: { script: 'echo' }) }

  describe '#timeout_value' do
    using RSpec::Parameterized::TableSyntax

    let(:ci_processable) { build(:ci_processable, metadata: ci_build_metadata) }
    let(:ci_build_metadata) { build(:ci_build_metadata, timeout: metadata_timeout) }

    subject(:timeout_value) { ci_processable.timeout_value }

    before do
      allow(ci_processable).to receive_messages(timeout: build_timeout)
    end

    where(:build_timeout, :metadata_timeout, :expected_timeout) do
      nil | nil | nil
      nil | 100 | 100
      200 | nil | 200
      200 | 100 | 200
    end

    with_them do
      it { is_expected.to eq(expected_timeout) }
    end
  end

  describe '#downstream_errors' do
    subject(:downstream_errors) { processable.downstream_errors }

    context 'when only job_messages are present' do
      before do
        create(:ci_job_message, job: processable, content: 'job message error')
      end

      it { is_expected.to eq(['job message error']) }
    end

    context 'when only metadata downstream errors are present' do
      before do
        allow(processable)
          .to receive(:options)
          .and_return({ downstream_errors: ['options error'] })
      end

      it { is_expected.to eq(['options error']) }
    end

    context 'when both are present' do
      before do
        create(:ci_job_message, job: processable, content: 'job message error')

        allow(processable)
          .to receive(:options)
          .and_return({ downstream_errors: ['options error'] })
      end

      it { is_expected.to eq(['job message error']) }
    end
  end

  describe '#enable_debug_trace!' do
    subject(:enable_debug_trace!) { processable.enable_debug_trace! }

    it 'sets job debug_trace_enabled to true' do
      expect { enable_debug_trace! }
        .to change { processable.read_attribute(:debug_trace_enabled) }
        .from(nil).to(true)
    end

    it 'does not change metadata.debug_trace_enabled' do
      expect { enable_debug_trace! }
        .to not_change { processable.metadata.debug_trace_enabled }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets metadata.debug_trace_enabled to true' do
        expect { enable_debug_trace! }
          .to change { processable.metadata.debug_trace_enabled }
          .from(false).to(true)
      end
    end
  end

  describe '#debug_trace_enabled?' do
    before do
      stub_feature_flags(ci_validate_config_options: false)
    end

    subject(:debug_trace_enabled?) { processable.debug_trace_enabled? }

    shared_examples 'when job debug_trace_enabled is nil' do
      context 'when metadata.debug_trace_enabled is true' do
        before do
          processable.metadata.update!(debug_trace_enabled: true)
        end

        it { is_expected.to be(true) }
      end

      context 'when metadata.debug_trace_enabled is false' do
        before do
          processable.metadata.update!(debug_trace_enabled: false)
        end

        it { is_expected.to be(false) }
      end

      context 'when metadata does not exist but job is not degenerated' do
        before do
          # Very old jobs populated this column instead of metadata
          processable.update_column(:options, '{}')
          processable.metadata.delete
          processable.reload
        end

        it { is_expected.to be(false) }
      end

      context 'when job is degenerated' do
        before do
          processable.degenerate!
          processable.reload
        end

        it { is_expected.to be(true) }
      end
    end

    it_behaves_like 'when job debug_trace_enabled is nil'

    context 'when job debug_trace_enabled is true' do
      before do
        processable.update!(debug_trace_enabled: true)
      end

      it { is_expected.to be(true) }

      context 'when FF `read_from_new_ci_destinations` is disabled' do
        before do
          stub_feature_flags(read_from_new_ci_destinations: false)
        end

        it_behaves_like 'when job debug_trace_enabled is nil'
      end
    end

    context 'when job debug_trace_enabled is false' do
      before do
        processable.update!(debug_trace_enabled: false)
      end

      it { is_expected.to be(false) }

      context 'when FF `read_from_new_ci_destinations` is disabled' do
        before do
          stub_feature_flags(read_from_new_ci_destinations: false)
        end

        it_behaves_like 'when job debug_trace_enabled is nil'
      end
    end
  end
end
