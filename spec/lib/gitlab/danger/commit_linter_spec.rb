# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require_relative 'danger_spec_helper'

require 'gitlab/danger/commit_linter'

RSpec.describe Gitlab::Danger::CommitLinter do
  using RSpec::Parameterized::TableSyntax

  let(:total_files_changed) { 2 }
  let(:total_lines_changed) { 10 }
  let(:stats) { { total: { files: total_files_changed, lines: total_lines_changed } } }
  let(:diff_parent) { Struct.new(:stats).new(stats) }
  let(:commit_class) do
    Struct.new(:message, :sha, :diff_parent)
  end

  let(:commit_message) { 'A commit message' }
  let(:commit_sha) { 'abcd1234' }
  let(:commit) { commit_class.new(commit_message, commit_sha, diff_parent) }

  subject(:commit_linter) { described_class.new(commit) }

  describe '#fixup?' do
    where(:commit_message, :is_fixup) do
      'A commit message' | false
      'fixup!' | true
      'fixup! A commit message' | true
      'squash!' | true
      'squash! A commit message' | true
    end

    with_them do
      it 'is true when commit message starts with "fixup!" or "squash!"' do
        expect(commit_linter.fixup?).to be(is_fixup)
      end
    end
  end

  describe '#suggestion?' do
    where(:commit_message, :is_suggestion) do
      'A commit message' | false
      'Apply suggestion to' | true
      'Apply suggestion to "A commit message"' | true
    end

    with_them do
      it 'is true when commit message starts with "Apply suggestion to"' do
        expect(commit_linter.suggestion?).to be(is_suggestion)
      end
    end
  end

  describe '#merge?' do
    where(:commit_message, :is_merge) do
      'A commit message' | false
      'Merge branch' | true
      'Merge branch "A commit message"' | true
    end

    with_them do
      it 'is true when commit message starts with "Merge branch"' do
        expect(commit_linter.merge?).to be(is_merge)
      end
    end
  end

  describe '#revert?' do
    where(:commit_message, :is_revert) do
      'A commit message' | false
      'Revert' | false
      'Revert "' | true
      'Revert "A commit message"' | true
    end

    with_them do
      it 'is true when commit message starts with "Revert \""' do
        expect(commit_linter.revert?).to be(is_revert)
      end
    end
  end

  describe '#multi_line?' do
    where(:commit_message, :is_multi_line) do
      "A commit message" | false
      "A commit message\n" | false
      "A commit message\n\n" | false
      "A commit message\n\nSigned-off-by: User Name <user@name.me>" | false
      "A commit message\n\nWith details" | true
    end

    with_them do
      it 'is true when commit message contains details' do
        expect(commit_linter.multi_line?).to be(is_multi_line)
      end
    end
  end

  describe '#failed?' do
    context 'with no failures' do
      it { expect(commit_linter).not_to be_failed }
    end

    context 'with failures' do
      before do
        commit_linter.add_problem(:details_line_too_long)
      end

      it { expect(commit_linter).to be_failed }
    end
  end

  describe '#add_problem' do
    it 'stores messages in #failures' do
      commit_linter.add_problem(:details_line_too_long)

      expect(commit_linter.problems).to eq({ details_line_too_long: described_class::PROBLEMS[:details_line_too_long] })
    end
  end

  shared_examples 'a valid commit' do
    it 'does not have any problem' do
      commit_linter.lint

      expect(commit_linter.problems).to be_empty
    end
  end

  describe '#lint' do
    describe 'subject' do
      context 'when subject valid' do
        it_behaves_like 'a valid commit'
      end

      context 'when subject is too short' do
        let(:commit_message) { 'A B' }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_too_short, described_class::DEFAULT_SUBJECT_DESCRIPTION)

          commit_linter.lint
        end
      end

      context 'when subject is too long' do
        let(:commit_message) { 'A B ' + 'C' * described_class::MAX_LINE_LENGTH }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_too_long, described_class::DEFAULT_SUBJECT_DESCRIPTION)

          commit_linter.lint
        end
      end

      context 'when subject is a WIP' do
        let(:final_message) { 'A B C' }
        # commit message with prefix will be over max length. commit message without prefix will be of maximum size
        let(:commit_message) { described_class::WIP_PREFIX + final_message + 'D' * (described_class::MAX_LINE_LENGTH - final_message.size) }

        it 'does not have any problems' do
          commit_linter.lint

          expect(commit_linter.problems).to be_empty
        end
      end

      context 'when subject is too short and too long' do
        let(:commit_message) { 'A ' + 'B' * described_class::MAX_LINE_LENGTH }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_too_short, described_class::DEFAULT_SUBJECT_DESCRIPTION)
          expect(commit_linter).to receive(:add_problem).with(:subject_too_long, described_class::DEFAULT_SUBJECT_DESCRIPTION)

          commit_linter.lint
        end
      end

      context 'when subject starts with lowercase' do
        let(:commit_message) { 'a B C' }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_starts_with_lowercase, described_class::DEFAULT_SUBJECT_DESCRIPTION)

          commit_linter.lint
        end
      end

      [
        '[ci skip] A commit message',
        '[Ci skip] A commit message',
        '[API] A commit message',
        'api: A commit message',
        'API: A commit message'
      ].each do |message|
        context "when subject is '#{message}'" do
          let(:commit_message) { message }

          it 'does not add a problem' do
            expect(commit_linter).not_to receive(:add_problem)

            commit_linter.lint
          end
        end
      end

      [
        '[ci skip]A commit message',
        '[Ci skip]  A commit message',
        '[ci skip] a commit message',
        'API: a commit message',
        'API: a commit message',
        'api: a commit message',
        '! A commit message'
      ].each do |message|
        context "when subject is '#{message}'" do
          let(:commit_message) { message }

          it 'adds a problem' do
            expect(commit_linter).to receive(:add_problem).with(:subject_starts_with_lowercase, described_class::DEFAULT_SUBJECT_DESCRIPTION)

            commit_linter.lint
          end
        end
      end

      context 'when subject ends with a period' do
        let(:commit_message) { 'A B C.' }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_ends_with_a_period, described_class::DEFAULT_SUBJECT_DESCRIPTION)

          commit_linter.lint
        end
      end
    end

    describe 'separator' do
      context 'when separator is missing' do
        let(:commit_message) { "A B C\n" }

        it_behaves_like 'a valid commit'
      end

      context 'when separator is a blank line' do
        let(:commit_message) { "A B C\n\nMore details." }

        it_behaves_like 'a valid commit'
      end

      context 'when separator is missing' do
        let(:commit_message) { "A B C\nMore details." }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:separator_missing)

          commit_linter.lint
        end
      end
    end

    describe 'details' do
      context 'when details are valid' do
        let(:commit_message) { "A B C\n\nMore details." }

        it_behaves_like 'a valid commit'
      end

      context 'when no details are given and many files are changed' do
        let(:total_files_changed) { described_class::MAX_CHANGED_FILES_IN_COMMIT + 1 }

        it_behaves_like 'a valid commit'
      end

      context 'when no details are given and many lines are changed' do
        let(:total_lines_changed) { described_class::MAX_CHANGED_LINES_IN_COMMIT + 1 }

        it_behaves_like 'a valid commit'
      end

      context 'when no details are given and many files and lines are changed' do
        let(:total_files_changed) { described_class::MAX_CHANGED_FILES_IN_COMMIT + 1 }
        let(:total_lines_changed) { described_class::MAX_CHANGED_LINES_IN_COMMIT + 1 }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:details_too_many_changes)

          commit_linter.lint
        end
      end

      context 'when details exceeds the max line length' do
        let(:commit_message) { "A B C\n\n" + 'D' * (described_class::MAX_LINE_LENGTH + 1) }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:details_line_too_long)

          commit_linter.lint
        end
      end

      context 'when details exceeds the max line length including URLs' do
        let(:commit_message) do
          "A B C\n\nsome message with https://example.com and https://gitlab.com" + 'D' * described_class::MAX_LINE_LENGTH
        end

        it_behaves_like 'a valid commit'
      end
    end

    describe 'message' do
      context 'when message includes a text emoji' do
        let(:commit_message) { "A commit message :+1:" }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:message_contains_text_emoji)

          commit_linter.lint
        end
      end

      context 'when message includes a unicode emoji' do
        let(:commit_message) { "A commit message 🚀" }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:message_contains_unicode_emoji)

          commit_linter.lint
        end
      end

      context 'when message includes a value that is surrounded by backticks' do
        let(:commit_message) { "A commit message `%20`" }

        it 'does not add a problem' do
          expect(commit_linter).not_to receive(:add_problem)

          commit_linter.lint
        end
      end

      context 'when message includes a short reference' do
        [
          'A commit message to fix #1234',
          'A commit message to fix !1234',
          'A commit message to fix &1234',
          'A commit message to fix %1234',
          'A commit message to fix gitlab#1234',
          'A commit message to fix gitlab!1234',
          'A commit message to fix gitlab&1234',
          'A commit message to fix gitlab%1234',
          'A commit message to fix gitlab-org/gitlab#1234',
          'A commit message to fix gitlab-org/gitlab!1234',
          'A commit message to fix gitlab-org/gitlab&1234',
          'A commit message to fix gitlab-org/gitlab%1234',
          'A commit message to fix "gitlab-org/gitlab%1234"',
          'A commit message to fix `gitlab-org/gitlab%1234'
        ].each do |message|
          let(:commit_message) { message }

          it 'adds a problem' do
            expect(commit_linter).to receive(:add_problem).with(:message_contains_short_reference)

            commit_linter.lint
          end
        end
      end
    end
  end
end
