# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Helpers, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let(:pipeline) { build(:ci_empty_pipeline, project_id: project.id) }
  let(:command) { instance_double(::Gitlab::Ci::Pipeline::Chain::Command, save_incompleted: true) }
  let(:message) { 'message' }

  let(:helper_class) do
    Class.new do
      include Gitlab::Ci::Pipeline::Chain::Helpers

      attr_accessor :pipeline, :command

      def initialize(pipeline, command)
        self.pipeline = pipeline
        self.command = command
      end
    end
  end

  subject(:helper) { helper_class.new(pipeline, command) }

  describe '.warning' do
    context 'when the warning includes malicious HTML' do
      let(:message) { '<div>gimme your password</div>' }
      let(:sanitized_message) { 'gimme your password' }

      it 'sanitizes' do
        helper.warning(message)

        expect(pipeline.warning_messages[0].content).to include(sanitized_message)
      end
    end
  end

  describe '.error' do
    shared_examples 'error function' do
      specify do
        expect(pipeline).to receive(:add_error_message).with(message).and_call_original

        if command.save_incompleted
          expect(pipeline).to receive(:ensure_project_iid!).twice.and_call_original
          expect(pipeline).to receive(:drop!).with(failure_reason).and_call_original
        end

        helper.error(message, failure_reason: failure_reason)

        expect(pipeline.yaml_errors).to eq(yaml_error)
        expect(pipeline.errors[:base]).to include(message)
        expect(pipeline.status).to eq 'failed'
        expect(pipeline.failure_reason).to eq failure_reason.to_s
      end
    end

    context 'when the error includes malicious HTML' do
      let(:message) { '<div>gimme your password</div>' }
      let(:sanitized_message) { 'gimme your password' }

      it 'sanitizes the error and removes the HTML tags' do
        helper.error(message, failure_reason: :config_error)

        expect(pipeline.yaml_errors).to eq(sanitized_message)
        expect(pipeline.errors[:base]).to include(sanitized_message)
      end
    end

    context 'when failure_reason is present' do
      context 'when failure_reason is `config_error`' do
        let(:failure_reason) { :config_error }
        let(:yaml_error) { message }

        it_behaves_like "error function"
      end

      context 'when failure_reason is nil' do
        let(:command) do
          instance_double(::Gitlab::Ci::Pipeline::Chain::Command, project: nil, dry_run?: false)
        end

        shared_examples "error function with no failure_reason" do
          it 'drops the pipeline without setting any failure_reason' do
            expect(command).to receive(:increment_pipeline_failure_reason_counter)

            call_error

            expect(pipeline.failure_reason).to be_nil
            expect(pipeline.yaml_errors).to be_nil
            expect(pipeline.errors[:base]).to include(message)
            expect(pipeline).to be_failed
            expect(pipeline).not_to be_persisted
          end
        end

        context 'when no failure_reason argument is passed' do
          let(:call_error) { helper.error(message) }

          it_behaves_like "error function with no failure_reason"
        end

        context 'when failure_reason argument is passed as nil' do
          let(:failure_reason) { nil }
          let(:call_error) { subject.error(message, failure_reason: failure_reason) }

          it_behaves_like "error function with no failure_reason"
        end
      end

      context 'when failure_reason is present but is not `config_error`' do
        let(:failure_reason) { :size_limit_exceeded }
        let(:yaml_error) { nil }

        it_behaves_like "error function"

        specify do
          helper.error(message, failure_reason: failure_reason)

          expect(pipeline).to be_persisted
        end

        context 'when the failure_reason is not persistable' do
          let(:failure_reason) { :filtered_by_rules }
          let(:command) { instance_double(::Gitlab::Ci::Pipeline::Chain::Command, project: nil, dry_run?: false) }

          specify do
            expect(command).to receive(:increment_pipeline_failure_reason_counter)

            helper.error(message, failure_reason: failure_reason)

            expect(pipeline).to be_failed
            expect(pipeline.failure_reason).to eq failure_reason.to_s
            expect(pipeline).not_to be_persisted
          end
        end

        context 'when save_incompleted is false' do
          let(:command) do
            instance_double(
              ::Gitlab::Ci::Pipeline::Chain::Command,
              save_incompleted: false, project: nil, dry_run?: false)
          end

          before do
            allow(command).to receive(:increment_pipeline_failure_reason_counter)
          end

          it_behaves_like "error function"

          specify do
            helper.error(message, failure_reason: failure_reason)

            expect(pipeline).not_to be_persisted
          end

          context 'with readonly pipeline and dry run enabled' do
            let(:command) do
              instance_double(
                ::Gitlab::Ci::Pipeline::Chain::Command,
                save_incompleted: true, project: nil, dry_run?: true)
            end

            before do
              pipeline.readonly!
            end

            specify do
              helper.error(message, failure_reason: failure_reason)

              expect(pipeline).to be_failed
              expect(pipeline.failure_reason).to eq failure_reason.to_s
              expect(pipeline).not_to be_persisted
            end
          end
        end
      end
    end
  end
end
