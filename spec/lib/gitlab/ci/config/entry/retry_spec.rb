# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Retry do
  let(:entry) { described_class.new(config) }

  shared_context 'when retry value is a numeric', :numeric do
    let(:config) { max }
    let(:max) {}
  end

  shared_context 'when retry value is a hash', :hash do
    let(:config) { { max: max, when: public_send(:when), exit_codes: public_send(:exit_codes) }.compact }
    let(:when) {}
    let(:exit_codes) {}
    let(:max) {}
  end

  describe '#value' do
    subject(:value) { entry.value }

    context 'when retry value is a numeric', :numeric do
      let(:max) { 2 }

      it 'is returned as a hash with max key' do
        expect(value).to eq(max: 2)
      end
    end

    context 'when retry value is a hash', :hash do
      context 'and `when` is a string' do
        let(:when) { 'unknown_failure' }

        it 'returns when wrapped in an array' do
          expect(value).to eq(when: ['unknown_failure'])
        end
      end

      context 'and `when` is an array' do
        let(:when) { %w[unknown_failure runner_system_failure] }

        it 'returns when as it was passed' do
          expect(value).to eq(when: %w[unknown_failure runner_system_failure])
        end
      end

      context 'and `exit_codes` is an integer' do
        let(:exit_codes) { 255 }

        it 'returns an array of exit_codes' do
          expect(value).to eq(exit_codes: [255])
        end
      end

      context 'and `exit_codes` is an array' do
        let(:exit_codes) { [255, 142] }

        it 'returns an array of exit_codes' do
          expect(value).to eq(exit_codes: [255, 142])
        end
      end
    end
  end

  describe 'validation' do
    context 'when retry value is correct' do
      context 'when it is a numeric', :numeric do
        let(:max) { 2 }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it is a hash', :hash do
        context 'with max' do
          let(:max) { 2 }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'with numeric exit_codes' do
          let(:exit_codes) { 255 }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'with hash values exit_codes' do
          let(:exit_codes) { [255, 142] }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'with string when' do
          let(:when) { 'unknown_failure' }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'with string when always' do
          let(:when) { 'always' }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'with array when' do
          let(:when) { %w[unknown_failure runner_system_failure] }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        # Those values are documented at `doc/ci/yaml/README.md`. If any of
        # those values gets invalid, documentation must be updated. To make
        # sure this is catched, check explicitly that all of the documented
        # values are valid. If they are not it means the documentation and this
        # array must be updated.
        retry_when_in_documentation = %w[
          always
          unknown_failure
          script_failure
          api_failure
          stuck_or_timeout_failure
          runner_system_failure
          runner_unsupported
          stale_schedule
          job_execution_timeout
          archived_failure
          unmet_prerequisites
          scheduler_failure
          data_integrity_failure
        ].freeze

        retry_when_in_documentation.each do |reason|
          context "with when from documentation `#{reason}`" do
            let(:when) { reason }

            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end

        ::Ci::Build.failure_reasons.each_key do |reason|
          context "with when from CommitStatus.failure_reasons `#{reason}`" do
            let(:when) { reason }

            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end
      end
    end

    context 'when retry value is not correct' do
      context 'when it is not a numeric nor an array' do
        let(:config) { true }

        it 'returns error about invalid type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'retry config has to be either an integer or a hash'
        end
      end

      context 'when it is a numeric', :numeric do
        context 'when it is lower than zero' do
          let(:max) { -1 }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry config must be greater than or equal to 0'
          end
        end

        context 'when it is not an integer' do
          let(:max) { 1.5 }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry config has to be either an integer or a hash'
          end
        end

        context 'when the value is too high' do
          let(:max) { 10 }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry config must be less than or equal to 2'
          end
        end
      end

      context 'when it is a hash', :hash do
        context 'with unknown keys' do
          let(:config) { { max: 2, unknown_key: :something, one_more: :key } }

          it 'returns error about the unknown key' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry config contains unknown keys: unknown_key, one_more'
          end
        end

        context 'with max lower than zero' do
          let(:max) { -1 }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry max must be greater than or equal to 0'
          end
        end

        context 'with max not an integer' do
          let(:max) { 1.5 }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry max must be an integer'
          end
        end

        context 'with max too high' do
          let(:max) { 10 }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry max must be less than or equal to 2'
          end
        end

        context 'with exit_codes in wrong format' do
          let(:exit_codes) { true }

          it 'raises an error' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry exit codes should be an array of integers or an integer'
          end
        end

        context 'with exit_codes in wrong array format' do
          let(:exit_codes) { ['string 1', 'string 2'] }

          it 'raises an error' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry exit codes should be an array of integers or an integer'
          end
        end

        context 'with exit_codes in wrong mixed array format' do
          let(:exit_codes) { [255, '155'] }

          it 'raises an error' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry exit codes should be an array of integers or an integer'
          end
        end

        context 'with when in wrong format' do
          let(:when) { true }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when should be an array of strings or a string'
          end
        end

        context 'with an unknown when string' do
          let(:when) { 'unknown_reason' }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when is not included in the list'
          end
        end

        context 'with an unknown failure reason in a when array' do
          let(:when) { %w[unknown_reason runner_system_failure] }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when contains unknown values: unknown_reason'
          end
        end
      end
    end
  end
end
