# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Metadatable, feature_category: :continuous_integration do
  let_it_be_with_refind(:processable) { create(:ci_processable, options: { script: 'echo' }) }

  before do
    # Remove when FF `stop_writing_builds_metadata` is removed
    processable.clear_memoization(:can_write_metadata?)
  end

  describe '#options' do
    let(:job) { build(:ci_build, :without_job_definition, metadata: nil) }
    let(:legacy_job_options) { { script: 'legacy job' } }
    let(:job_definition_options) { { script: 'job_definition' } }
    let(:temp_job_definition_options) { { script: 'temp_job_definition' } }
    let(:metadata_options) { { script: 'metadata' } }

    subject(:options) { job.options }

    it 'defaults to an empty hash' do
      is_expected.to eq({})
    end

    context 'when metadata options are present' do
      before do
        job.ensure_metadata.write_attribute(:config_options, metadata_options)
      end

      it { is_expected.to eq(metadata_options) }

      context 'when temp job definition options are present' do
        before do
          temp_job_definition = build(:ci_job_definition, config: { options: temp_job_definition_options })
          job.write_attribute(:temp_job_definition, temp_job_definition)
        end

        it { is_expected.to eq(temp_job_definition_options) }

        context 'when job definition options are present' do
          before do
            job.build_job_definition.write_attribute(:config, { options: job_definition_options })
          end

          it { is_expected.to eq(job_definition_options) }

          context 'when legacy job options are present' do
            before do
              job.write_attribute(:options, legacy_job_options)
            end

            it { is_expected.to eq(legacy_job_options) }
          end
        end
      end
    end
  end

  describe '#yaml_variables' do
    let(:job) { build(:ci_build, :without_job_definition, metadata: nil) }
    let(:legacy_job_variables) { [{ key: 'VAR', value: 'legacy job' }] }
    let(:job_definition_variables) { [{ key: 'VAR', value: 'job_definition' }] }
    let(:temp_job_definition_variables) { [{ key: 'VAR', value: 'temp_job_definition' }] }
    let(:metadata_variables) { [{ key: 'VAR', value: 'metadata' }] }

    subject(:yaml_variables) { job.yaml_variables }

    it 'defaults to an empty array' do
      is_expected.to eq([])
    end

    context 'when metadata variables are present' do
      before do
        job.ensure_metadata.write_attribute(:config_variables, metadata_variables)
      end

      it { is_expected.to eq(metadata_variables) }

      context 'when temp job definition variables are present' do
        before do
          temp_job_definition = build(:ci_job_definition, config: { yaml_variables: temp_job_definition_variables })
          job.write_attribute(:temp_job_definition, temp_job_definition)
        end

        it { is_expected.to eq(temp_job_definition_variables) }

        context 'when job definition variables are present' do
          before do
            job.build_job_definition.write_attribute(:config, { yaml_variables: job_definition_variables })
          end

          it { is_expected.to eq(job_definition_variables) }

          context 'when legacy job variables are present' do
            before do
              job.write_attribute(:yaml_variables, legacy_job_variables)
            end

            it { is_expected.to eq(legacy_job_variables) }
          end
        end
      end
    end
  end

  describe '#options=' do
    let(:options) { { script: 'echo test' } }

    subject(:set_options) { processable.options = options }

    before do
      processable.ensure_metadata
      processable.write_attribute(:options, { script: 'echo something' })
    end

    it 'does not change metadata.config_options' do
      expect { set_options }
        .to not_change { processable.metadata.config_options }
    end

    it 'does not set legacy job options to nil' do
      expect { set_options }
        .to not_change { processable.read_attribute(:options) }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets value into metadata.config_options' do
        expect { set_options }
          .to change { processable.metadata.config_options }.to(options)
      end

      it 'sets legacy job options to nil' do
        expect { set_options }
          .to change { processable.read_attribute(:options) }.to(nil)
      end
    end
  end

  describe '#yaml_variables=' do
    let(:yaml_variables) { [{ key: 'VAR', value: 'test' }] }

    subject(:set_yaml_variables) { processable.yaml_variables = yaml_variables }

    before do
      processable.ensure_metadata
      processable.write_attribute(:yaml_variables, [{ key: 'VAR', value: 'something' }])
    end

    it 'does not change metadata.config_variables' do
      expect { set_yaml_variables }
        .to not_change { processable.metadata.config_variables }
    end

    it 'does not set legacy job yaml_variables to nil' do
      expect { set_yaml_variables }
        .to not_change { processable.read_attribute(:yaml_variables) }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets value into metadata.config_variables' do
        expect { set_yaml_variables }
          .to change { processable.metadata.config_variables }.to(yaml_variables)
      end

      it 'sets legacy job yaml_variables to nil' do
        expect { set_yaml_variables }
          .to change { processable.read_attribute(:yaml_variables) }.to(nil)
      end
    end
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
        processable.ensure_metadata

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
        processable.ensure_metadata

        expect { update_timeout_state }
          .to not_change { processable.metadata.timeout }
          .and not_change { processable.metadata.timeout_source }
      end

      context 'when FF `stop_writing_builds_metadata` is disabled' do
        before do
          stub_feature_flags(stop_writing_builds_metadata: false)
          processable.ensure_metadata
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

    context 'when metadata exists' do
      before do
        job.ensure_metadata.save!
      end

      it { is_expected.to eq('unknown_timeout_source') }
    end

    context 'when metadata does not exist' do
      before do
        job.metadata&.delete
        job.reload
      end

      it { is_expected.to eq('unknown_timeout_source') }
    end

    context 'when job timeout_source is present' do
      before do
        job.write_attribute(:timeout_source, 2)
      end

      it { is_expected.to eq('project_timeout_source') }
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
      processable.ensure_metadata

      expect { enable_debug_trace! }
        .to not_change { processable.metadata.debug_trace_enabled }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
        processable.ensure_metadata
      end

      it 'sets metadata.debug_trace_enabled to true' do
        expect { enable_debug_trace! }
          .to change { processable.metadata.debug_trace_enabled }
          .from(false).to(true)
      end
    end
  end

  describe '#debug_trace_enabled?' do
    subject(:debug_trace_enabled?) { processable.debug_trace_enabled? }

    shared_examples 'when job debug_trace_enabled is nil' do
      context 'when metadata.debug_trace_enabled is true' do
        before do
          processable.ensure_metadata.update!(
            debug_trace_enabled: true,
            config_options: { image: 'image:1.0' } # job is not degenerated
          )
        end

        it { is_expected.to be(true) }
      end

      context 'when metadata.debug_trace_enabled is false' do
        before do
          processable.ensure_metadata.update!(
            debug_trace_enabled: false,
            config_options: { image: 'image:1.0' } # job is not degenerated
          )
        end

        it { is_expected.to be(false) }
      end

      context 'when metadata does not exist but job is not degenerated' do
        before do
          # Very old jobs populated this column instead of metadata
          processable.update_column(:options, '{}')
          processable.metadata&.delete
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
    end

    context 'when job debug_trace_enabled is false' do
      before do
        processable.update!(debug_trace_enabled: false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#id_tokens' do
    let(:metadata_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://metadata' } } }
    let(:job_definition_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://job.definition' } } }
    let(:temp_job_definition_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://temp.job.definition' } } }

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

      context 'when temp job definition id_tokens are present' do
        before do
          temp_job_definition = build(:ci_job_definition, config: { id_tokens: temp_job_definition_id_tokens })
          processable.write_attribute(:temp_job_definition, temp_job_definition)
        end

        it { is_expected.to eq(temp_job_definition_id_tokens) }

        context 'when job definition id_tokens are present' do
          before do
            updated_config = processable.job_definition.config.merge(id_tokens: job_definition_id_tokens)
            processable.job_definition.write_attribute(:config, updated_config)
          end

          it 'returns job definition id_tokens' do
            expect(id_tokens).to eq(job_definition_id_tokens)
            expect(processable.id_tokens?).to be(true)
          end
        end
      end
    end
  end

  describe '#id_tokens=' do
    let(:new_id_tokens) { { 'TEST_ID_TOKEN' => { 'aud' => 'https://client.test' } } }

    subject(:set_id_tokens) { processable.id_tokens = new_id_tokens }

    before do
      processable.ensure_metadata.save!
    end

    it 'does not change metadata.id_tokens' do
      expect { set_id_tokens }
        .to not_change { processable.metadata.id_tokens }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
      end

      it 'sets the value into metadata.id_tokens' do
        expect { set_id_tokens }
          .to change { processable.metadata.id_tokens }
          .from({}).to(new_id_tokens)
      end
    end
  end

  describe '#exit_code' do
    subject(:exit_code) { processable.exit_code }

    it { is_expected.to be_nil }

    context 'when metadata exit_code is present' do
      before do
        processable.ensure_metadata.write_attribute(:exit_code, 1)
      end

      it { is_expected.to eq(1) }

      context 'when job exit_code is present' do
        before do
          processable.write_attribute(:exit_code, 2)
        end

        it { is_expected.to eq(2) }
      end
    end
  end

  describe '#exit_code=' do
    let(:existing_exit_code) { 1 }
    let(:new_exit_code) { nil }

    subject(:set_exit_code) { processable.exit_code = new_exit_code }

    before do
      processable.write_attribute(:exit_code, existing_exit_code)
      processable.ensure_metadata.write_attribute(:exit_code, existing_exit_code)
    end

    it 'does not change job exit_code nor metadata exit_code value' do
      expect { set_exit_code }
        .to not_change { processable.read_attribute(:exit_code) }
        .and not_change { processable.metadata.exit_code }
    end

    context 'when the new exit_code is not nil' do
      using RSpec::Parameterized::TableSyntax

      where(:new_exit_code, :expected_exit_code) do
        2     | 2
        -3    | 0
        0     | 0
        500   | 500
        40000 | 32767
      end

      with_them do
        it 'updates job exit_code with the expected value' do
          expect { set_exit_code }
            .to change { processable.read_attribute(:exit_code) }
            .from(existing_exit_code).to(expected_exit_code)
        end

        it 'does not change metadata exit_code value' do
          expect { set_exit_code }
            .to not_change { processable.metadata.exit_code }
        end

        context 'when FF `stop_writing_builds_metadata` is disabled' do
          before do
            stub_feature_flags(stop_writing_builds_metadata: false)
          end

          it 'updates metadata exit_code with the expected value' do
            expect { set_exit_code }
              .to change { processable.metadata.exit_code }
              .from(existing_exit_code).to(expected_exit_code)
          end
        end
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
      end
    end
  end

  describe '#interruptible=' do
    it 'does not change metadata.interruptible' do
      processable.ensure_metadata

      expect { processable.interruptible = true }
        .to not_change { processable.metadata.interruptible }
    end

    context 'when FF `stop_writing_builds_metadata` is disabled' do
      before do
        stub_feature_flags(stop_writing_builds_metadata: false)
        processable.ensure_metadata
      end

      it 'sets the value into metadata.interruptible' do
        expect { processable.interruptible = true }
          .to change { processable.metadata.interruptible }
      end
    end
  end
end
