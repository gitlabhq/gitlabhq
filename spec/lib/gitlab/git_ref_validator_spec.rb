# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitRefValidator, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  # Valid ref names that should pass validation in both implementations
  let(:valid_refs) do
    [
      'feature/new',
      'implement_@all',
      'my_new_feature',
      'my-branch',
      '#1',
      'feature/refs/heads/foo',
      'master{yesterday',
      'master}yesterday',
      'master{yesterday}',
      '@' # Single @ is valid - becomes refs/heads/@ which doesn't violate rule 9
    ]
  end

  # Invalid ref names that should fail validation in both implementations
  # Format: [ref_name, description]
  # Ordered according to git-check-ref-format rules:
  # https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
  let(:invalid_refs) do
    [
      # Rule 1: No component can begin with '.' or end with '.lock'
      ['.tag', 'component starts with dot (rule 1)'],
      ['sub.lock/webmatrix', '.lock in middle component (rule 1)'],

      # Rule 3: Cannot have two consecutive dots '..'
      ['feature..branch', 'double dots (rule 3)'],

      # Rule 4: Cannot have ASCII control chars, space, ~, ^, :
      ['feature/~new/', 'tilde (rule 4)'],
      ['feature/^new/', 'caret (rule 4)'],
      ['feature/:new/', 'colon (rule 4)'],
      ['feature new', 'space (rule 4)'],
      ['my branch', 'space in name (rule 4)'],
      ['+foo:bar', 'plus and colon (rule 4)'],
      ['foo:bar', 'colon (rule 4)'],

      # Rule 5: Cannot have ?, *, or [
      ['feature/?new/', 'question mark (rule 5)'],
      ['feature/*new/', 'asterisk (rule 5)'],
      ['feature/[new/', 'open bracket (rule 5)'],

      # Rule 6: Cannot begin/end with '/' or contain '//'
      ['feature/new/', 'trailing slash (rule 6)'],
      ['feature//new', 'double slash (rule 6)'],

      # Rule 7: Cannot end with a dot '.'
      ['feature/new.', 'trailing dot (rule 7)'],

      # Rule 8: Cannot contain '@{'
      ['feature\@{', '@{ sequence (rule 8)'],

      # Rule 10: Cannot contain '\'
      ['feature\new', 'backslash (rule 10)'],

      # Branch-specific: Cannot start with dash
      ['-', 'single dash'],
      ['-branch', 'leading dash']
    ]
  end

  # Rule 4: Cannot have ASCII control characters (bytes 0x00-0x1F)
  let(:control_char_refs) do
    (0x00..0x1f).map do |byte|
      ["test#{byte.chr}branch", "control char 0x#{byte.to_s(16).upcase.rjust(2, '0')} (rule 4)"]
    end
  end

  # Rule 4: Control characters in different positions
  let(:control_char_position_refs) do
    [
      ["\x00test", 'NULL at start (rule 4)'],
      ["test\x00", 'NULL at end (rule 4)'],
      ["te\x00st", 'NULL in middle (rule 4)'],
      ["feature\tbranch", 'TAB (rule 4)'],
      ["feature\nbranch", 'newline (rule 4)'],
      ["feature\rbranch", 'carriage return (rule 4)']
    ]
  end

  shared_examples 'ref name validation' do
    describe '.validate' do
      context 'with valid ref names' do
        where(:ref_name) { valid_refs }

        with_them do
          it { expect(described_class.validate(ref_name)).to be true }
        end
      end

      context 'with invalid ref names' do
        where(:ref_name, :description) { invalid_refs }

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end

      context 'with control characters (0x00-0x1F)' do
        where(:ref_name, :description) { control_char_refs }

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end

      context 'with control characters in different positions' do
        where(:ref_name, :description) { control_char_position_refs }

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end

      context 'with refs/heads/ and refs/remotes/ prefixes' do
        where(:ref_name) do
          ['refs/heads/', 'refs/remotes/', 'refs/heads/feature', 'refs/remotes/origin']
        end

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end

      it 'rejects empty string' do
        expect(described_class.validate("")).to be false
      end

      it 'rejects nil' do
        expect(described_class.validate(nil)).to be false
      end

      it 'rejects HEAD without skip_head_ref_check' do
        expect(described_class.validate('HEAD')).to be false
      end

      it 'rejects invalid byte sequences' do
        expect(described_class.validate("\xA0\u0000\xB0")).to be false
      end

      context 'when skip_head_ref_check is true' do
        it 'allows HEAD' do
          expect(described_class.validate('HEAD', skip_head_ref_check: true)).to be true
        end
      end
    end

    describe '.validate_merge_request_branch' do
      context 'with valid ref names' do
        where(:ref_name) { valid_refs + ['HEAD', 'refs/heads/master'] }

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be true }
        end
      end

      context 'with invalid ref names' do
        where(:ref_name, :description) { invalid_refs }

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end

      context 'with control characters (0x00-0x1F)' do
        where(:ref_name, :description) { control_char_refs }

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end

      context 'with control characters in different positions' do
        where(:ref_name, :description) { control_char_position_refs }

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end

      context 'with empty refs/heads/ and refs/remotes/' do
        where(:ref_name) { ['refs/heads/', 'refs/remotes/'] }

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end

      it 'rejects empty string' do
        expect(described_class.validate_merge_request_branch("")).to be false
      end

      it 'rejects nil' do
        expect(described_class.validate_merge_request_branch(nil)).to be false
      end

      it 'rejects invalid byte sequences' do
        expect(described_class.validate_merge_request_branch("\xA0\u0000\xB0")).to be false
      end
    end
  end

  context 'with git_ref_validator_custom_validation feature flag enabled' do
    before do
      stub_feature_flags(git_ref_validator_custom_validation: true)
    end

    include_examples 'ref name validation'

    describe '.validate with custom validation specific cases' do
      # DEL character (0x7F) - only rejected by custom validation (Rugged bug)
      # Rule 4: Cannot have ASCII control characters including DEL (0x7F)
      context 'with DEL character (0x7F)' do
        where(:ref_name, :description) do
          [
            ["test\x7fbranch", 'DEL in middle'],
            ["\x7f", 'single DEL'],
            ["\x7ftest", 'DEL at start'],
            ["test\x7f", 'DEL at end'],
            ["\x00\x1F\x7F", 'multiple control chars with DEL'],
            ["feature\x08\x7fbranch", 'BS + DEL']
          ]
        end

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end

      # Rule 1: Component cannot start with . or end with .lock
      context 'with .lock suffix and hidden components' do
        where(:ref_name, :description) do
          [
            ['feature/.hidden', 'hidden component'],
            ['branch.lock', '.lock suffix'],
            ['feature/branch.lock', '.lock in last component'],
            ['feature/branch.lock/sub', '.lock in middle component']
          ]
        end

        with_them do
          it { expect(described_class.validate(ref_name)).to be false }
        end
      end
    end

    describe '.validate_merge_request_branch with custom validation specific cases' do
      # Rule 4: Cannot have ASCII control characters including DEL (0x7F)
      context 'with DEL character (0x7F)' do
        where(:ref_name, :description) do
          [
            ["test\x7fbranch", 'DEL in middle'],
            ["\x7f", 'single DEL'],
            ["\x7ftest", 'DEL at start'],
            ["test\x7f", 'DEL at end'],
            ["\x00\x1F\x7F", 'multiple control chars with DEL'],
            ["feature\x08\x7fbranch", 'BS + DEL']
          ]
        end

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end

      # Rule 1: Component cannot start with . or end with .lock
      context 'with .lock suffix and hidden components' do
        where(:ref_name, :description) do
          [
            ['feature/.hidden', 'hidden component'],
            ['branch.lock', '.lock suffix'],
            ['feature/branch.lock', '.lock in last component'],
            ['feature/branch.lock/sub', '.lock in middle component']
          ]
        end

        with_them do
          it { expect(described_class.validate_merge_request_branch(ref_name)).to be false }
        end
      end
    end
  end

  context 'with git_ref_validator_custom_validation feature flag disabled' do
    before do
      stub_feature_flags(git_ref_validator_custom_validation: false)
    end

    include_examples 'ref name validation'

    describe '.validate with legacy Rugged validation (known bug)' do
      # DEL character (0x7F) - Rugged incorrectly allows this (rule 4 violation)
      it 'allows DEL character (Rugged bug)' do
        expect(described_class.validate("test\x7fbranch")).to be true
        expect(described_class.validate("\x7f")).to be true
      end

      # .lock suffix - Rugged correctly rejects this
      it 'rejects .lock suffix' do
        expect(described_class.validate('branch.lock')).to be false
      end
    end

    describe '.validate_merge_request_branch with legacy Rugged validation (known bug)' do
      # DEL character (0x7F) - Rugged incorrectly allows this (rule 4 violation)
      it 'allows DEL character (Rugged bug)' do
        expect(described_class.validate_merge_request_branch("test\x7fbranch")).to be true
        expect(described_class.validate_merge_request_branch("\x7f")).to be true
      end

      # .lock suffix - Rugged correctly rejects this
      it 'rejects .lock suffix' do
        expect(described_class.validate_merge_request_branch('branch.lock')).to be false
      end
    end
  end
end
