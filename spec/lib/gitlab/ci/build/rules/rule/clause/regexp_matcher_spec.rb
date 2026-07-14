# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::RegexpMatcher, feature_category: :pipeline_composition do
  let(:max_length) { Gitlab::Ci::Build::Rules::Rule::Clause::REGEXP_MAX_LENGTH }
  let(:raw_pattern) { '^src/.*' }
  let(:expanded_pattern) { raw_pattern }
  let(:max_comparisons) { 50_000 }
  let(:project_id) { 42 }

  subject(:matcher) do
    described_class.new(
      raw_pattern: raw_pattern,
      expanded_pattern: expanded_pattern,
      max_comparisons: max_comparisons,
      log_scope: 'rules:changes',
      project_id: project_id
    )
  end

  describe '#validate_pattern_length!' do
    context 'when the expanded pattern is within the limit' do
      it 'does not raise' do
        expect { matcher.validate_pattern_length! }.not_to raise_error
      end
    end

    context 'when the expanded pattern exceeds the limit' do
      let(:expanded_pattern) { 'a' * (max_length + 1) }

      it 'raises a ParseError' do
        expect { matcher.validate_pattern_length! }.to raise_error(
          Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
          "rules:changes:regexp is too long (maximum is #{max_length} characters after variable expansion)"
        )
      end
    end
  end

  describe '#match?' do
    context 'when a path matches' do
      it { expect(matcher.match?(['src/main.rb', 'README.md'])).to be(true) }
    end

    context 'when no path matches' do
      it { expect(matcher.match?(['README.md'])).to be(false) }
    end

    context 'when the number of paths exceeds max_comparisons' do
      let(:max_comparisons) { 2 }

      it 'returns true and logs without compiling', :aggregate_failures do
        expect(Regexp).not_to receive(:new)
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          hash_including(
            message: 'rules:changes regexp comparisons limit exceeded',
            project_id: project_id,
            extra: { paths_size: 3, regexp: raw_pattern }
          )
        )

        expect(matcher.match?(%w[a b c])).to be(true)
      end
    end

    context 'when a match times out' do
      let(:compiled) { instance_double(Regexp) }

      before do
        allow(Regexp).to receive(:new).and_return(compiled)
        allow(compiled).to receive(:match?).and_raise(Regexp::TimeoutError)
      end

      it 'logs a warning and raises a ParseError', :aggregate_failures do
        expect(Gitlab::AppJsonLogger).to receive(:warn).with(
          hash_including(
            message: 'rules:changes regexp match timed out',
            project_id: project_id,
            extra: { regexp: raw_pattern }
          )
        )

        expect { matcher.match?(['src/main.rb']) }.to raise_error(
          Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
          /rules:changes:regexp timed out/
        )
      end
    end

    context 'when the total time budget is exceeded' do
      let(:budget) { Gitlab::Ci::Build::Rules::Rule::Clause::REGEXP_TOTAL_TIMEOUT_SECONDS }

      before do
        # First call sets the deadline; subsequent calls (checked per path) are past it.
        allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(0, budget + 1)
      end

      it 'logs a warning and raises a ParseError without evaluating the path', :aggregate_failures do
        expect(Gitlab::AppJsonLogger).to receive(:warn).with(
          hash_including(
            message: 'rules:changes regexp total time budget exceeded',
            project_id: project_id,
            extra: { regexp: raw_pattern }
          )
        )

        expect { matcher.match?(['no/match/here.txt']) }.to raise_error(
          Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
          /rules:changes:regexp exceeded the time budget/
        )
      end
    end

    context 'when the raw pattern contains control characters' do
      let(:raw_pattern) { "^src/\n.*" }
      let(:max_comparisons) { 0 }

      it 'strips control characters from the logged pattern' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          hash_including(extra: hash_including(regexp: '^src/.*'))
        )

        matcher.match?(['anything'])
      end
    end
  end
end
