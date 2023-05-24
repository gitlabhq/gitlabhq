# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Errors, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  describe '.merge_nested_errors' do
    it 'merges nested collection errors' do
      issue = project.issues.new(
        title: 'test',
        notes: [
          Note.new(
            award_emoji: [AwardEmoji.new(name: 'test')]
          )
        ],
        sentry_issue: SentryIssue.new
      )

      issue.validate

      expect(issue.errors.full_messages)
        .to contain_exactly(
          "Author can't be blank",
          "Notes is invalid",
          "Sentry issue sentry issue identifier can't be blank"
        )

      described_class.merge_nested_errors(issue)

      expect(issue.errors.full_messages)
        .to contain_exactly(
          "Notes is invalid",
          "Author can't be blank",
          "Sentry issue sentry issue identifier can't be blank",
          "Award emoji is invalid",
          "Note can't be blank",
          "Project can't be blank",
          "Noteable can't be blank",
          "Author can't be blank",
          "Project does not match noteable project",
          "User can't be blank",
          "Name is not a valid emoji name"
        )
    end
  end
end
