# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Helpers, feature_category: :continuous_integration do
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

  let(:pipeline) { build(:ci_empty_pipeline) }
  let(:command) { double(save_incompleted: true) }
  let(:message) { 'message' }

  describe '.warning' do
    context 'when the warning includes malicious HTML' do
      let(:message) { '<div>gimme your password</div>' }
      let(:sanitized_message) { 'gimme your password' }

      it 'sanitizes' do
        subject.warning(message)

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
          expect(pipeline).to receive(:drop!).with(drop_reason).and_call_original
        end

        subject.error(message, config_error: config_error, drop_reason: drop_reason)

        expect(pipeline.yaml_errors).to eq(yaml_error)
        expect(pipeline.errors[:base]).to include(message)
        expect(pipeline.status).to eq 'failed'
        expect(pipeline.failure_reason).to eq drop_reason.to_s
      end
    end

    context 'when the error includes malicious HTML' do
      let(:message) { '<div>gimme your password</div>' }
      let(:sanitized_message) { 'gimme your password' }

      it 'sanitizes the error and removes the HTML tags' do
        subject.error(message, config_error: true, drop_reason: :config_error)

        expect(pipeline.yaml_errors).to eq(sanitized_message)
        expect(pipeline.errors[:base]).to include(sanitized_message)
      end
    end

    context 'when given a drop reason' do
      context 'when config error is true' do
        context 'sets the yaml error and overrides the drop reason' do
          let(:drop_reason) { :config_error }
          let(:config_error) { true }
          let(:yaml_error) { message }

          it_behaves_like "error function"
        end
      end

      context 'when drop_reason is nil' do
        let(:command) { double(project: nil) }

        shared_examples "error function with no drop reason" do
          it 'drops with out failure reason' do
            expect(command).to receive(:increment_pipeline_failure_reason_counter)

            call_error

            expect(pipeline.failure_reason).to be_nil
            expect(pipeline.yaml_errors).to be_nil
            expect(pipeline.errors[:base]).to include(message)
            expect(pipeline).to be_failed
            expect(pipeline).not_to be_persisted
          end
        end

        context 'when no drop_reason argument is passed' do
          let(:call_error) { subject.error(message) }

          it_behaves_like "error function with no drop reason"
        end

        context 'when drop_reason argument is passed as nil' do
          let(:drop_reason) { nil }
          let(:call_error) { subject.error(message, drop_reason: drop_reason) }

          it_behaves_like "error function with no drop reason"
        end
      end

      context 'when config error is false' do
        context 'does not set the yaml error or override the drop reason' do
          let(:drop_reason) { :size_limit_exceeded }
          let(:config_error) { false }
          let(:yaml_error) { nil }

          it_behaves_like "error function"

          specify do
            subject.error(message, config_error: config_error, drop_reason: drop_reason)

            expect(pipeline).to be_persisted
          end

          context 'when the drop reason is not persistable' do
            let(:drop_reason) { :filtered_by_rules }
            let(:command) { double(project: nil) }

            specify do
              expect(command).to receive(:increment_pipeline_failure_reason_counter)

              subject.error(message, config_error: config_error, drop_reason: drop_reason)

              expect(pipeline).to be_failed
              expect(pipeline.failure_reason).to eq drop_reason.to_s
              expect(pipeline).not_to be_persisted
            end
          end

          context 'when save_incompleted is false' do
            let(:command) { double(save_incompleted: false, project: nil) }

            before do
              allow(command).to receive(:increment_pipeline_failure_reason_counter)
            end

            it_behaves_like "error function"

            specify do
              subject.error(message, config_error: config_error, drop_reason: drop_reason)

              expect(pipeline).not_to be_persisted
            end
          end
        end
      end
    end
  end
end
