# frozen_string_literal: true

require 'rspec-parameterized'
require_relative 'danger_spec_helper'

require_relative '../../../tooling/danger/merge_request_linter'

RSpec.describe Tooling::Danger::MergeRequestLinter do
  using RSpec::Parameterized::TableSyntax

  let(:mr_class) do
    Struct.new(:message, :sha, :diff_parent)
  end

  let(:mr_title) { 'A B ' + 'C' }
  let(:merge_request) { mr_class.new(mr_title, anything, anything) }

  describe '#lint_subject' do
    subject(:mr_linter) { described_class.new(merge_request) }

    shared_examples 'a valid mr title' do
      it 'does not have any problem' do
        mr_linter.lint

        expect(mr_linter.problems).to be_empty
      end
    end

    context 'when subject valid' do
      it_behaves_like 'a valid mr title'
    end

    context 'when it is too long' do
      let(:mr_title) { 'A B ' + 'C' * described_class::MAX_LINE_LENGTH }

      it 'adds a problem' do
        expect(mr_linter).to receive(:add_problem).with(:subject_too_long, described_class.subject_description)

        mr_linter.lint
      end
    end

    describe 'using magic mr run options' do
      where(run_option: described_class.mr_run_options_regex.split('|') +
        described_class.mr_run_options_regex.split('|').map! { |x| "[#{x}]" })

      with_them do
        let(:mr_title) { run_option + ' A B ' + 'C' * (described_class::MAX_LINE_LENGTH - 5) }

        it_behaves_like 'a valid mr title'
      end
    end
  end
end
