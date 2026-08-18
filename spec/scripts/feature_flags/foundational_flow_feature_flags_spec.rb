# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/feature_flags/foundational_flow_feature_flags'

RSpec.describe FoundationalFlowFeatureFlags, feature_category: :feature_flags do
  describe '.feature_flag_name' do
    subject(:feature_flag_name) { described_class.feature_flag_name(described_class.parse(source)) }

    let(:source) { nil }

    context 'when feature_flag is a String' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: "real_flag" }
          end
        end
        RUBY
      end

      it { is_expected.to eq('real_flag') }
    end

    context 'when feature_flag is a Symbol' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: :real_flag }
          end
        end
        RUBY
      end

      it { is_expected.to eq('real_flag') }
    end

    context 'when no feature flag config' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1" }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is no configuration method at all' do
      let(:source) do
        <<~RUBY
        module X
          def something_else
            { feature_flag: "nope" }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when feature_flag: is a keyword argument on an unrelated method' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def other_method(feature_flag: "should_not_match")
          end

          def configuration
            { foundational_flow_reference: "x/v1" }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when feature_flag: is returned by an unrelated helper method' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1" }
          end

          def helper
            { feature_flag: "should_not_match_either" }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when feature_flag is a constant assigned a String earlier in the same file' do
      let(:source) do
        <<~RUBY
        module X
          SOME_CONST = "real_flag"

          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: SOME_CONST }
          end
        end
        RUBY
      end

      it { is_expected.to eq('real_flag') }
    end

    context 'when feature_flag is a constant assigned a Symbol earlier in the same file' do
      let(:source) do
        <<~RUBY
        module X
          SOME_CONST = :real_flag

          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: SOME_CONST }
          end
        end
        RUBY
      end

      it { is_expected.to eq('real_flag') }
    end

    context 'when feature_flag is a constant assigned another constant earlier in the same file' do
      let(:source) do
        <<~RUBY
        module X
          OTHER_CONST = "real_flag"
          SOME_CONST = OTHER_CONST

          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: SOME_CONST }
          end
        end
        RUBY
      end

      it { is_expected.to eq('real_flag') }
    end

    context 'when feature_flag is a constant not defined anywhere in the file' do
      let(:source) do
        <<~RUBY
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: SOME_CONST }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when feature_flag is a constant assigned a non-literal value' do
      let(:source) do
        <<~RUBY
        module X
          SOME_CONST = compute_flag_name

          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: SOME_CONST }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when feature_flag is an interpolated string' do
      let(:source) do
        <<~'RUBY'
        module X
          module_function

          def configuration
            { foundational_flow_reference: "x/v1", feature_flag: "prefix_#{suffix}" }
          end
        end
        RUBY
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.parse' do
    it 'returns nil for unparsable source instead of raising' do
      expect(described_class.parse('def broken(')).to be_nil
    end
  end
end
