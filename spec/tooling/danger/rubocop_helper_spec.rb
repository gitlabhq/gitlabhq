# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/rubocop_helper'
require_relative '../../../tooling/danger/rubocop_discourage_todo_addition'
require_relative '../../../tooling/danger/rubocop_inline_disable_suggestion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RubocopHelper, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:rubocop) { fake_danger.new(helper: fake_helper) }

  before do
    allow(fake_helper).to receive(:changed_lines).and_return([])
  end

  describe 'rubocop inline disable suggestor danger' do
    let(:all_changed_files) { %w[app/models/user.rb something.rb doc.md Gemfile] }
    let(:draft_mr?) { false }

    before do
      allow(fake_helper).to receive(:all_changed_files).and_return(all_changed_files)
      allow(fake_helper).to receive(:draft_mr?).and_return(draft_mr?)
    end

    it 'processes the right amount of files' do
      expect(rubocop).to receive(:add_inline_disable_suggestions_for).exactly(3).times.and_call_original

      rubocop.execute_inline_disable_suggestor
    end

    context 'when it is a draft mr' do
      let(:draft_mr?) { true }

      it 'does not perform any processing of files' do
        expect(rubocop).not_to receive(:add_inline_disable_suggestions_for)

        rubocop.execute_inline_disable_suggestor
      end
    end
  end

  describe 'rubocop discourage todo addition danger' do
    using RSpec::Parameterized::TableSyntax

    let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }

    where do
      {
        'with only todo files' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml],
          modified_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml],
          suggest_calls: 0
        },
        'with only todo files and Gemfile.lock' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml Gemfile.lock],
          modified_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml Gemfile.lock],
          suggest_calls: 0
        },
        'with todo files and other files' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml app/models/user.rb],
          modified_files: %w[.rubocop_todo/foo/foo.yml .rubocop_todo/this/bar.yml app/models/user.rb],
          suggest_calls: 2
        },
        'with added or removed todo files and other files' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml app/models/user.rb],
          modified_files: %w[app/models/user.rb],
          suggest_calls: 0
        },
        'with todo files and Gemfile' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml Gemfile Gemfile],
          modified_files: %w[.rubocop_todo/foo/foo.yml Gemfile Gemfile],
          suggest_calls: 0
        },
        'with todo files and rubocop config file' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml .rubocop.yml],
          modified_files: %w[.rubocop_todo/foo/foo.yml .rubocop.yml],
          suggest_calls: 0
        },
        'with todo files Gemfile and other files' => {
          all_changed_files: %w[.rubocop_todo/foo/foo.yml Gemfile app/models/user.rb],
          modified_files: %w[.rubocop_todo/foo/foo.yml Gemfile app/models/user.rb],
          suggest_calls: 0
        }
      }
    end

    with_them do
      before do
        allow(fake_helper).to receive(:all_changed_files).and_return(all_changed_files)
        allow(fake_helper).to receive(:modified_files).and_return(modified_files)
        allow(rubocop).to receive(:project_helper).and_return(fake_project_helper)
        allow(fake_project_helper).to receive(:file_lines).and_return([])
      end

      specify do
        expect(rubocop).to receive(:add_todo_suggestion_for).exactly(suggest_calls).times.and_call_original

        rubocop.execute_todo_suggestor
      end
    end
  end
end
