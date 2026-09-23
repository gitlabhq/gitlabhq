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
          '\\\\g<1>',
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

    context 'with a subroutine call' do
      where(:pattern) do
        [
          '(?:\\g<1>|Z)(x)\\g<1>',
          "(?:\\g'n'|Z)(?<n>x)",
          '\\g<0>',
          # Onigmo still treats these as calls, so the guard cannot rely on \\g
          # sitting next to its argument.
          '(?<n>ab)\\g(?#c)<n>',
          "(?x:(?<n>ab)\\g#c\n<n>)"
        ]
      end

      with_them do
        it 'raises RegexpError without compiling #security', :aggregate_failures do
          expect(Regexp).not_to receive(:new)
          expect { described_class.compile_regexp(pattern) }
            .to raise_error(RegexpError, /uses a subroutine call/)
        end
      end
    end

    context 'with a repeat count over the limit' do
      where(:pattern) do
        [
          '(?:.{46341,}){46341}',
          '(?:.{65000,}){65000}',
          '(?:.{92815,}){18,46273}',
          '(?:a){1,5000}',
          '(?:a){5000,}'
        ]
      end

      with_them do
        it 'raises RegexpError without compiling #security', :aggregate_failures do
          expect(Regexp).not_to receive(:new)
          expect { described_class.compile_regexp(pattern) }
            .to raise_error(RegexpError, /over the 1000 limit/)
        end
      end
    end

    context 'with repeat counts at or under the limit' do
      where(:pattern) do
        [
          '(?:a){1000}',
          '[[:alnum:]_\\-./]{1,200}\\.rb\\z',
          '(?:[a-z]{1,50}/){1,20}[a-z]{1,50}',
          '\\d{4}/\\d{2}/\\d{2}/.*',
          'a\\{5000\\}'
        ]
      end

      with_them do
        it 'compiles the pattern as written' do
          expect(described_class.compile_regexp(pattern).source).to eq(Regexp.new(pattern).source)
        end
      end
    end

    # REPEAT_MAX is calibrated against the densest body that fits REGEXP_MAX_LENGTH.
    # Unicode tables grow between Ruby versions, so recompute the bound rather than
    # trusting the constant.
    it 'keeps REPEAT_MAX under the size that lets Onigmo unroll a repeat #security' do
      max_length = Gitlab::Ci::Build::Rules::Rule::Clause::REGEXP_MAX_LENGTH
      cap = described_class::REPEAT_MAX
      budget = max_length - "(?:){#{cap}}".length

      worst = %w[c l cn ll idc].map do |prop|
        unit = "\\p{#{prop}}"
        body = (unit * (budget / unit.length)).dup.force_encoding(Encoding::UTF_8)
        ObjectSpace.memsize_of(Regexp.new(body))
      end.max

      expect(worst * cap).to be < 2**31
    end

    context 'when the compiled program exceeds the size limit' do
      # Short enough to clear REGEXP_MAX_LENGTH, but each property class compiles to
      # roughly 6KB of Unicode code ranges.
      let(:pattern) { '\\p{Assigned}' * 21 }

      before do
        stub_const("#{described_class}::REGEXP_MAX_COMPILED_BYTES", 1024)
      end

      it 'raises RegexpError naming the compiled size #security' do
        expect { described_class.compile_regexp(pattern) }
          .to raise_error(RegexpError, /compiles to \d+ bytes, over the 1024 byte limit/)
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
