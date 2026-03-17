# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/prevent_index_creation_suggestion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::PreventIndexCreationSuggestion, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper, file_lines: file_lines) }
  let(:filename) { 'db/migrate/20260000000000_add_index_to_users.rb' }
  let(:file_lines) { changed_lines.map { |line| line.delete_prefix('+') } }

  let(:changed_lines) { [] }

  subject(:suggestion) { fake_danger.new(helper: fake_helper) }

  before do
    allow(suggestion).to receive(:project_helper).and_return(fake_project_helper)
    allow(suggestion.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)

    suggestion.define_singleton_method(:add_suggestions_for) do |filename|
      Tooling::Danger::PreventIndexCreationSuggestion.new(filename, context: self).suggest
    end
  end

  context 'when cop is disabled without a URL' do
    let(:changed_lines) { ["+# rubocop:disable Migration/PreventIndexCreation"] }

    it 'adds a suggestion comment' do
      expect(suggestion).to receive(:markdown).with(
        a_string_including('Migration/PreventIndexCreation'),
        hash_including(file: filename)
      )

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when cop is disabled with a comment but no URL' do
    let(:changed_lines) { ["+# rubocop:disable Migration/PreventIndexCreation -- We need this index"] }

    it 'adds a suggestion comment' do
      expect(suggestion).to receive(:markdown).with(
        a_string_including('Migration/PreventIndexCreation'),
        hash_including(file: filename)
      )

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when cop is marked as todo without a URL' do
    let(:changed_lines) { ["+# rubocop:todo Migration/PreventIndexCreation"] }

    it 'adds a suggestion comment' do
      expect(suggestion).to receive(:markdown).with(
        a_string_including('Migration/PreventIndexCreation'),
        hash_including(file: filename)
      )

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when cop is disabled with a valid GitLab work_item URL' do
    let(:changed_lines) do
      ["+# rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/123456"]
    end

    it 'does not add a suggestion comment' do
      expect(suggestion).not_to receive(:markdown)

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when multiple cops are disabled without a URL' do
    let(:changed_lines) { ["+# rubocop:disable Migration/PreventIndexCreation, Migration/AnotherCop"] }

    it 'adds a suggestion comment' do
      expect(suggestion).to receive(:markdown).with(
        a_string_including('Migration/PreventIndexCreation'),
        hash_including(file: filename)
      )

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when multiple cops are disabled with a valid URL' do
    let(:changed_lines) do
      ["+# rubocop:disable Migration/PreventIndexCreation, Migration/AnotherCop -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/789"]
    end

    it 'does not add a suggestion comment' do
      expect(suggestion).not_to receive(:markdown)

      suggestion.add_suggestions_for(filename)
    end
  end

  context 'when file does not contain Migration/PreventIndexCreation disable' do
    let(:changed_lines) { ["+add_concurrent_index :users, :email, name: INDEX_NAME"] }

    it 'does not add a suggestion comment' do
      expect(suggestion).not_to receive(:markdown)

      suggestion.add_suggestions_for(filename)
    end
  end
end
