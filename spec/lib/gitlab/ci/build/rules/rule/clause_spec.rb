# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause, feature_category: :pipeline_composition do
  describe '.compile_regexp' do
    using RSpec::Parameterized::TableSyntax

    context 'with a valid pattern' do
      where(:pattern) do
        [
          '\A(?!docs/).*',
          '^(?:src|lib|spec)/',
          'a|b',
          '[a|b]',
          'a\|b',
          'a\\\\|b',
          '(?#c|omment)x',
          '(?<n>a)|\k<n>',
          '(a)(?(1)x|y)',
          'x(?=a|b)'
        ]
      end

      with_them do
        it 'compiles the pattern as written' do
          expect(described_class.compile_regexp(pattern).source).to eq(Regexp.new(pattern).source)
        end
      end

      it 'passes the timeout through' do
        expect(described_class.compile_regexp('a|b', timeout: 0.05).timeout).to eq(0.05)
      end
    end

    # Passed straight to Regexp.new, each of these aborts the process on Ruby 3.3 and 3.4.
    context 'with a pattern that hits the Onigmo alternation bug', :aggregate_failures do
      where(:pattern) do
        [
          '|{100001}',
          'a|{100001}',
          '|{1,100001}',
          '|{2,1}',
          '|(?#',
          '|\k<0',
          "|\\k'k",
          '(a|(?#'
        ]
      end

      with_them do
        it 'raises RegexpError naming the original pattern' do
          expect { described_class.compile_regexp(pattern) }
            .to raise_error(RegexpError, /#{Regexp.escape("/#{pattern}/")}\z/)
        end
      end
    end
  end

  describe '.fabricate' do
    using RSpec::Parameterized::TableSyntax

    let(:value) { 'some value' }

    subject { described_class.fabricate(type, value) }

    context 'when type is valid' do
      where(:type, :value, :result) do
        'changes' | 'some value'  | Gitlab::Ci::Build::Rules::Rule::Clause::Changes
        'exists'  | { paths: [] } | Gitlab::Ci::Build::Rules::Rule::Clause::Exists
        'if'      | 'some value'  | Gitlab::Ci::Build::Rules::Rule::Clause::If
      end

      with_them do
        it { is_expected.to be_instance_of(result) }
      end
    end

    context 'when type is invalid' do
      let(:type) { 'when' }

      it { is_expected.to be_nil }

      context "when type is 'variables'" do
        let(:type) { 'variables' }

        it { is_expected.to be_nil }
      end
    end
  end
end
