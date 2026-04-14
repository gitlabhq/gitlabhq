# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../support/matchers/result_matchers'
require_relative '../../../../../tooling/ai_harness/doctor/steps/parse_argv'

RSpec.describe AiHarness::Doctor::Steps::ParseArgv, feature_category: :tooling do
  include ResultMatchers

  let(:base_context) { { results: [] } }

  before do
    stub_const('ARGV', argv)
  end

  describe '.parse' do
    context 'with no arguments' do
      let(:argv) { [] }

      it 'returns Result.ok with fix: false and print_help: false' do
        result = described_class.parse(base_context)

        expect(result).to be_ok_result do |value|
          expect(value).to include(fix: false, print_help: false)
        end
      end
    end

    context 'with --fix' do
      let(:argv) { ['--fix'] }

      it 'returns Result.ok with fix: true and print_help: false' do
        result = described_class.parse(base_context)

        expect(result).to be_ok_result do |value|
          expect(value).to include(fix: true, print_help: false)
        end
      end
    end

    context 'with --help' do
      let(:argv) { ['--help'] }

      it 'returns Result.ok with print_help: true' do
        result = described_class.parse(base_context)

        expect(result).to be_ok_result do |value|
          expect(value).to include(print_help: true, fix: false)
        end
      end
    end

    context 'with --fix and --help together' do
      let(:argv) { ['--fix', '--help'] }

      it 'returns Result.ok with print_help: true (--help takes precedence)' do
        result = described_class.parse(base_context)

        expect(result).to be_ok_result do |value|
          expect(value).to include(print_help: true)
        end
      end
    end

    context 'with unknown option' do
      let(:argv) { ['--unknown'] }

      it 'returns Result.err with InvalidArguments message' do
        result = described_class.parse(base_context)

        expect(result).to be_err_result do |message|
          expect(message).to be_a(AiHarness::Doctor::Messages::InvalidArguments)
          expect(message.content).to include(exit_code: 1)
          expect(message.content.fetch(:stderr_text)).to include('Unknown option: --unknown')
        end
      end

      it 'includes help text in the stderr_text' do
        result = described_class.parse(base_context)

        expect(result).to be_err_result do |message|
          expect(message.content.fetch(:stderr_text)).to include('Usage:')
          expect(message.content.fetch(:stderr_text)).to include('--fix')
          expect(message.content.fetch(:stderr_text)).to include('--help')
        end
      end
    end
  end
end
