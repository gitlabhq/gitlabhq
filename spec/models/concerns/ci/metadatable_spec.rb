# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Metadatable, feature_category: :continuous_integration do
  let_it_be_with_refind(:processable) { create(:ci_processable, options: { script: 'echo' }) }

  before do
    # Remove when FF `read_from_new_ci_destinations` is removed
    processable.clear_memoization(:read_from_new_destination?)
    # Remove when FF `stop_writing_builds_metadata` is removed
    processable.clear_memoization(:can_write_metadata?)
  end

  describe '#timeout_human_readable_value' do
    let_it_be_with_refind(:job) { create(:ci_build) }

    subject(:timeout_human_readable_value) { job.timeout_human_readable_value }

    it { is_expected.to be_nil }

    context 'when metadata timeout is present' do
      before do
        job.ensure_metadata.write_attribute(:timeout, 60)
      end

      it { is_expected.to eq('1m') }

      context 'when job timeout is present' do
        before do
          job.write_attribute(:timeout, 120)
        end

        it { is_expected.to eq('2m') }

        context 'when FF `read_from_new_ci_destinations` is disabled' do
          before do
            stub_feature_flags(read_from_new_ci_destinations: false)
          end

          it { is_expected.to eq('1m') }
        end
      end
    end
  end

  describe '#timeout_value' do
    subject(:timeout_value) { processable.timeout_value }

    it { is_expected.to be_nil }

    context 'when metadata timeout is present' do
      before do
        processable.ensure_metadata.write_attribute(:timeout, 60)
      end

      it { is_expected.to eq(60) }

      context 'when job timeout is present' do
        before do
          processable.write_attribute(:timeout, 120)
        end

        it { is_expected.to eq(120) }

        context 'when FF `read_from_new_ci_destinations` is disabled' do
          before do
            stub_feature_flags(read_from_new_ci_destinations: false)
          end

          it { is_expected.to eq(60) }
        end
      end
    end
  end

  describe '#update_timeout_state' do
    let(:calculator) { instance_double(::Ci::Builds::TimeoutCalculator) }

    subject(:update_timeout_state) { processable.update_timeout_state }

    before do
      allow(::Ci::Builds::TimeoutCalculator).to receive(:new).with(processable).and_return(calculator)
    end

    context 'when no timeouts defined anywhere' do
      before do
        allow(calculator).to receive(:applicable_timeout).and_return(nil)
      end

      it { is_expected.to be_nil }

      it 'does not change job timeout nor metadata timeout values' do
        expect { update_timeout_state }
          .to not_change { processable.read_attribute(:timeout) }
          .and not_change { processable.read_attribute(:timeout_source) }
          .and not_change { processable.metadata.timeout }
          .and not_change { processable.metadata.timeout_source }
      end
    end

    context 'when at least a timeout is defined' do
      before do
        allow(calculator)
          .to receive(:applicable_timeout)
          .and_return(::Ci::Builds::Timeout.new(25, 4))
      end

      it { is_expected.to be(true) }

      it 'updates job timeout values' do
        expect { update_timeout_state }
          .to change { processable.read_attribute(:timeout) }.from(nil).to(25)
          .and change { processable.read_attribute(:timeout_source) }.from(nil).to(4)
      end

      it 'does not change metadata timeout values' do
        expect { update_timeout_state }
          .to not_change { processable.metadata.timeout }
          .and not_change { processable.metadata.timeout_source }
      end

      context 'when FF `stop_writing_builds_metadata` is disabled' do
        before do
          stub_feature_flags(stop_writing_builds_metadata: false)
        end

        it { is_expected.to be(true) }

        it 'updates metadata timeout values' do
          expect { update_timeout_state }
            .to change { processable.metadata.timeout }.from(nil).to(25)
            .and change { processable.metadata.timeout_source }.from('unknown_timeout_source').to('job_timeout_source')
        end

        context 'when metadata timeout values fail to save' do
          before do
            allow(processable.metadata).to receive(:update).and_return(false)
          end

          it { is_expected.to be(false) }

          it 'does not change job timeout values' do
            expect { update_timeout_state }
              .to not_change { processable.read_attribute(:timeout) }
              .and not_change { processable.read_attribute(:timeout_source) }
          end
        end
      end

      context 'when job timeout values are invalid' do
        before do
          allow(processable).to receive(:valid?).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#timeout_source_value' do
    let_it_be_with_refind(:job) { create(:ci_build) }

    subject(:timeout_source_value) { job.timeout_source_value }

    it { is_expected.to eq('unknown_timeout_source') }

    context 'when metadata does not exist' do
      before do
        job.delete
      end

      it { is_expected.to be_nil }
    end

    context 'when job timeout_source is present' do
      before do
        job.write_attribute(:timeout_source, 2)
      end

      it { is_expected.to eq('project_timeout_source') }

      context 'when FF `read_from_new_ci_destinations` is disabled' do
        before do
          stub_feature_flags(read_from_new_ci_destinations: false)
        end

        it { is_expected.to eq('unknown_timeout_source') }
      end
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

  describe '#id_tokens' do
    let(:metadata_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://metadata' } } }
    let(:job_definition_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://job.definition' } } }

    subject(:id_tokens) { processable.id_tokens }

    it 'defaults to an empty hash' do
      expect(id_tokens).to eq({})
      expect(processable.id_tokens?).to be(false)
    end

    context 'when metadata id_tokens are present' do
      before do
        processable.ensure_metadata.write_attribute(:id_tokens, metadata_id_tokens)
      end

      it 'returns metadata id_tokens' do
        expect(id_tokens).to eq(metadata_id_tokens)
        expect(processable.id_tokens?).to be(true)
      end

      context 'when job definition id_tokens are present' do
        before do
          updated_config = processable.job_definition.config.merge(id_tokens: job_definition_id_tokens)
          processable.job_definition.write_attribute(:config, updated_config)
        end

        it 'returns job definition id_tokens' do
          expect(id_tokens).to eq(job_definition_id_tokens)
          expect(processable.id_tokens?).to be(true)
        end

        context 'when FF `read_from_new_ci_destinations` is disabled' do
          before do
            stub_feature_flags(read_from_new_ci_destinations: false)
          end

          it 'returns metadata id_tokens' do
            expect(id_tokens).to eq(metadata_id_tokens)
            expect(processable.id_tokens?).to be(true)
          end
        end
      end
    end
  end

  describe '#id_tokens=' do
    let(:id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://client.test' } } }

    subject(:set_id_tokens) { processable.id_tokens = id_tokens }

    it 'does not change metadata.id_tokens' do
      expect { set_id_tokens }
        .to not_change { processable.metadata.id_tokens }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets the value into metadata.id_tokens' do
        set_id_tokens

        expect(processable.metadata.id_tokens).to eq(id_tokens)
      end
    end
  end

  describe '#interruptible' do
    subject(:interruptible) { processable.interruptible }

    context 'when metadata interruptible is present' do
      before do
        processable.job_definition = nil
        processable.ensure_metadata.write_attribute(:interruptible, true)
      end

      it 'returns metadata interruptible' do
        expect(interruptible).to be_truthy
      end

      context 'when job definition interruptible is present' do
        before do
          processable.ensure_metadata.write_attribute(:interruptible, nil)
          processable.build_job_definition.write_attribute(:interruptible, false)
        end

        it 'returns job definition interruptible' do
          expect(interruptible).to be false
        end

        context 'when FF `read_from_new_ci_destinations` is disabled' do
          before do
            stub_feature_flags(read_from_new_ci_destinations: false)
            processable.ensure_metadata.write_attribute(:interruptible, true)
            processable.job_definition.interruptible = false
          end

          it 'returns metadata interruptible' do
            expect(interruptible).to be_truthy
          end
        end
      end
    end
  end

  describe '#interruptible=' do
    it 'does not change metadata.interruptible' do
      expect { processable.interruptible = true }
        .to not_change { processable.metadata.interruptible }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets the value into metadata.interruptible' do
        expect { processable.interruptible = true }
          .to change { processable.metadata.interruptible }
      end
    end
  end
end
