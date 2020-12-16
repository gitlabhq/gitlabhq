# frozen_string_literal: true

require 'fast_spec_helper'
require_relative 'danger_spec_helper'

require 'gitlab/danger/base_linter'

RSpec.describe Gitlab::Danger::BaseLinter do
  let(:commit_class) do
    Struct.new(:message, :sha, :diff_parent)
  end

  let(:commit_message) { 'A commit message' }
  let(:commit) { commit_class.new(commit_message, anything, anything) }

  subject(:commit_linter) { described_class.new(commit) }

  describe '#failed?' do
    context 'with no failures' do
      it { expect(commit_linter).not_to be_failed }
    end

    context 'with failures' do
      before do
        commit_linter.add_problem(:subject_too_long, described_class.subject_description)
      end

      it { expect(commit_linter).to be_failed }
    end
  end

  describe '#add_problem' do
    it 'stores messages in #failures' do
      commit_linter.add_problem(:subject_too_long, '%s')

      expect(commit_linter.problems).to eq({ subject_too_long: described_class.problems_mapping[:subject_too_long] })
    end
  end

  shared_examples 'a valid commit' do
    it 'does not have any problem' do
      commit_linter.lint_subject

      expect(commit_linter.problems).to be_empty
    end
  end

  describe '#lint_subject' do
    context 'when subject valid' do
      it_behaves_like 'a valid commit'
    end

    context 'when subject is too short' do
      let(:commit_message) { 'A B' }

      it 'adds a problem' do
        expect(commit_linter).to receive(:add_problem).with(:subject_too_short, described_class.subject_description)

        commit_linter.lint_subject
      end
    end

    context 'when subject is too long' do
      let(:commit_message) { 'A B ' + 'C' * described_class::MAX_LINE_LENGTH }

      it 'adds a problem' do
        expect(commit_linter).to receive(:add_problem).with(:subject_too_long, described_class.subject_description)

        commit_linter.lint_subject
      end
    end

    context 'when subject is a WIP' do
      let(:final_message) { 'A B C' }
      # commit message with prefix will be over max length. commit message without prefix will be of maximum size
      let(:commit_message) { described_class::WIP_PREFIX + final_message + 'D' * (described_class::MAX_LINE_LENGTH - final_message.size) }

      it 'does not have any problems' do
        commit_linter.lint_subject

        expect(commit_linter.problems).to be_empty
      end
    end

    context 'when subject is too short and too long' do
      let(:commit_message) { 'A ' + 'B' * described_class::MAX_LINE_LENGTH }

      it 'adds a problem' do
        expect(commit_linter).to receive(:add_problem).with(:subject_too_short, described_class.subject_description)
        expect(commit_linter).to receive(:add_problem).with(:subject_too_long, described_class.subject_description)

        commit_linter.lint_subject
      end
    end

    context 'when subject starts with lowercase' do
      let(:commit_message) { 'a B C' }

      it 'adds a problem' do
        expect(commit_linter).to receive(:add_problem).with(:subject_starts_with_lowercase, described_class.subject_description)

        commit_linter.lint_subject
      end
    end

    [
      '[ci skip] A commit message',
      '[Ci skip] A commit message',
      '[API] A commit message',
      'api: A commit message',
      'API: A commit message',
      'API: a commit message',
      'API: a commit message'
    ].each do |message|
      context "when subject is '#{message}'" do
        let(:commit_message) { message }

        it 'does not add a problem' do
          expect(commit_linter).not_to receive(:add_problem)

          commit_linter.lint_subject
        end
      end
    end

    [
      '[ci skip]A commit message',
      '[Ci skip]  A commit message',
      '[ci skip] a commit message',
      'api: a commit message',
      '! A commit message'
    ].each do |message|
      context "when subject is '#{message}'" do
        let(:commit_message) { message }

        it 'adds a problem' do
          expect(commit_linter).to receive(:add_problem).with(:subject_starts_with_lowercase, described_class.subject_description)

          commit_linter.lint_subject
        end
      end
    end

    context 'when subject ends with a period' do
      let(:commit_message) { 'A B C.' }

      it 'adds a problem' do
        expect(commit_linter).to receive(:add_problem).with(:subject_ends_with_a_period, described_class.subject_description)

        commit_linter.lint_subject
      end
    end
  end
end
