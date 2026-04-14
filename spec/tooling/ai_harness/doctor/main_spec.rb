# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../tooling/ai_harness/doctor/main'

RSpec.describe AiHarness::Doctor::Main, feature_category: :tooling do
  describe '.main' do
    before do
      allow($stdout).to receive(:print)
      allow($stderr).to receive(:print)
    end

    let(:initial_context) { { results: [] } }

    shared_examples 'invokes all steps in order' do
      it 'calls steps in the correct order' do
        expect(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse).with(initial_context).ordered do |ctx|
          ctx[:print_help] = false
          ctx[:fix] = false
          ctx[:stdout_text] = 'output'
          ctx[:exit_code] = 0
          Gitlab::Fp::Result.ok(ctx)
        end
        expect(AiHarness::Doctor::Steps::HandleAction).to receive(:handle).ordered { |ctx| ctx }

        described_class.main
      end
    end

    describe 'happy path' do
      include_examples 'invokes all steps in order'

      it 'returns exit code 0 on success' do
        allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |ctx|
          ctx[:print_help] = false
          ctx[:fix] = false
          ctx[:stdout_text] = 'output'
          ctx[:exit_code] = 0
          Gitlab::Fp::Result.ok(ctx)
        end
        allow(AiHarness::Doctor::Steps::HandleAction).to receive(:handle) { |ctx| ctx }

        expect(described_class.main).to eq(0)
      end

      it 'prints stdout_text to stdout via inspect_ok' do
        allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |ctx|
          ctx[:print_help] = false
          ctx[:fix] = false
          ctx[:stdout_text] = 'check output'
          ctx[:exit_code] = 0
          Gitlab::Fp::Result.ok(ctx)
        end
        allow(AiHarness::Doctor::Steps::HandleAction).to receive(:handle) { |ctx| ctx }

        described_class.main

        expect($stdout).to have_received(:print).with('check output')
      end
    end

    describe 'error cases' do
      context 'when ParseArgv returns InvalidArguments' do
        it 'returns exit code 1 and prints to stderr via inspect_err' do
          allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |_ctx|
            Gitlab::Fp::Result.err(
              AiHarness::Doctor::Messages::InvalidArguments.new(
                { stderr_text: 'Unknown option: --foo', exit_code: 1 }
              )
            )
          end

          expect(described_class.main).to eq(1)
          expect($stderr).to have_received(:print).with('Unknown option: --foo')
        end

        it 'short-circuits the chain — no further steps run' do
          allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |_ctx|
            Gitlab::Fp::Result.err(
              AiHarness::Doctor::Messages::InvalidArguments.new(
                { stderr_text: 'error', exit_code: 1 }
              )
            )
          end

          expect(AiHarness::Doctor::Steps::HandleAction).not_to receive(:handle)

          described_class.main
        end
      end

      context 'when an unmatched Result type is returned' do
        it 'raises UnmatchedResultError' do
          allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |_ctx|
            Gitlab::Fp::Result.err(Class.new(Gitlab::Fp::Message).new({ stderr_text: 'x', exit_code: 1 }))
          end

          expect { described_class.main }.to raise_error(Gitlab::Fp::UnmatchedResultError)
        end
      end
    end
  end
end
