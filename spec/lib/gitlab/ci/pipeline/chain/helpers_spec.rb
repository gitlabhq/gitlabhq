# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Helpers do
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

  describe '.error' do
    shared_examples 'error function' do
      specify do
        expect(pipeline).to receive(:drop!).with(drop_reason).and_call_original
        expect(pipeline).to receive(:add_error_message).with(message).and_call_original
        expect(pipeline).to receive(:ensure_project_iid!).twice.and_call_original

        subject.error(message, config_error: config_error, drop_reason: drop_reason)

        expect(pipeline.yaml_errors).to eq(yaml_error)
        expect(pipeline.errors[:base]).to include(message)
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

      context 'when config error is false' do
        context 'does not set the yaml error or override the drop reason' do
          let(:drop_reason) { :size_limit_exceeded }
          let(:config_error) { false }
          let(:yaml_error) { nil }

          it_behaves_like "error function"
        end
      end
    end
  end
end
