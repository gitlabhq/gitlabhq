require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Retry do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when retry value is correct' do
      context 'when it is a numeric' do
        let(:config) { 2 }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it is a hash without when' do
        let(:config) { { max: 2 } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it is a hash with string when' do
        let(:config) { { max: 2, when: 'unknown_failure' } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it is a hash with string when always' do
        let(:config) { { max: 2, when: 'always' } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when it is a hash with array when' do
        let(:config) { { max: 2, when: %w[unknown_failure runner_system_failure] } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      # Those values are documented at `doc/ci/yaml/README.md`. If any of
      # those values gets invalid, documentation must be updated. To make
      # sure this is catched, check explicitly that all of the documented
      # values are valid. If they are not it means the documentation and this
      # array must be updated.
      RETRY_WHEN_IN_DOCUMENTATION = %w[
          always
          unknown_failure
          script_failure
          api_failure
          stuck_or_timeout_failure
          runner_system_failure
          missing_dependency_failure
          runner_unsupported
      ].freeze

      RETRY_WHEN_IN_DOCUMENTATION.each do |reason|
        context "when it is a hash with value from documentation `#{reason}`" do
          let(:config) { { max: 2, when: reason } }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end
    end

    context 'when retry value is not correct' do
      context 'when it is not a numeric nor an array' do
        let(:config) { true }

        it 'returns error about invalid type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job retry should be a hash or an integer'
        end
      end

      context 'not defined as a hash' do
        context 'when it is lower than zero' do
          let(:config) { -1 }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry config must be greater than or equal to 0'
          end
        end

        context 'when it is not an integer' do
          let(:config) { 1.5 }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job retry should be a hash or an integer'
          end
        end

        context 'when the value is too high' do
          let(:config) { 10 }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry config must be less than or equal to 2'
          end
        end
      end

      context 'defined as a hash' do
        context 'with unknown keys' do
          let(:config) { { max: 2, unknown_key: :something, one_more: :key } }

          it 'returns error about the unknown key' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry config contains unknown keys: unknown_key, one_more'
          end
        end

        context 'when max is lower than zero' do
          let(:config) { { max: -1 } }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'retry max must be greater than or equal to 0'
          end
        end

        context 'when max is not an integer' do
          let(:config) { { max: 1.5 } }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry max must be an integer'
          end
        end

        context 'when max is too high' do
          let(:config) { { max: 10 } }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry max must be less than or equal to 2'
          end
        end

        context 'when when has the wrong format' do
          let(:config) { { when: true } }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when should be an array of strings or a string'
          end
        end

        context 'when when is a string and unknown' do
          let(:config) { { when: 'unknown_reason' } }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when is not included in the list'
          end
        end

        context 'when when is an array and includes unknown failures' do
          let(:config) { { when: %w[unknown_reason runner_system_failure] } }

          it 'returns error about the wrong format' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'retry when contains unknown values: unknown_reason'
          end
        end
      end
    end
  end
end
