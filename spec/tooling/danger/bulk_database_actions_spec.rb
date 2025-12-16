# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/bulk_database_actions'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::BulkDatabaseActions, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:comment_text) { "\n#{described_class::SUGGESTION}" }
  let(:file_lines) { file_diff.map { |line| line.delete_prefix('+') } }

  before do
    allow(bulk_database_actions).to receive(:project_helper).and_return(fake_project_helper)
    allow(bulk_database_actions.project_helper).to receive(:file_lines).and_return(file_lines)
    allow(bulk_database_actions.helper).to receive(:added_files).and_return([filename])
    allow(bulk_database_actions.helper).to receive(:changed_lines).with(filename).and_return(file_diff)

    bulk_database_actions.define_singleton_method(:add_suggestions_for) do |filename|
      Tooling::Danger::BulkDatabaseActions.new(filename, context: self).suggest
    end
  end

  subject(:bulk_database_actions) { fake_danger.new(helper: fake_helper) }

  context 'for single line method call' do
    let(:file_diff) do
      <<~DIFF.split("\n")
        +    def execute
        +      #{code}
        +
        +      ServiceResponse.success
        +    end
      DIFF
    end

    context 'when file is a non-spec Ruby file' do
      let(:filename) { 'app/services/personal_access_tokens/revoke_token_family_service.rb' }

      using RSpec::Parameterized::TableSyntax

      context 'when comment is expected' do
        where(:code) do
          [
            'update_all(revoked: true)',
            'destroy_all',
            'delete_all',
            'update(revoked: true)',
            'delete',
            'upsert',
            'upsert_all',
            'User.upsert',
            'User.last.destroy',
            'destroy',
            ' .destroy',
            'bulk_update',
            'bulk_delete',
            'bulk_upsert!',
            'bulk_insert!',
            'scope :published, ->'
          ]
        end

        with_them do
          specify do
            expect(bulk_database_actions).to receive(:markdown).with(comment_text.chomp, file: filename, line: 2)

            bulk_database_actions.add_suggestions_for(filename)
          end
        end
      end

      context 'when no comment is expected' do
        where(:code) do
          [
            'we update bob',
            'update_two_factor',
            'delete_keys(key)',
            'destroy_hook(hook)',
            'destroy_all_merged',
            'update_all_mirrors',
            'update_scope'
          ]
        end

        with_them do
          specify do
            expect(bulk_database_actions).not_to receive(:markdown)

            bulk_database_actions.add_suggestions_for(filename)
          end
        end
      end
    end
  end

  context 'for single line ActiveRecord scope change' do
    context 'when file is a non-spec Ruby file' do
      let(:filename) { 'app/services/personal_access_tokens/revoke_token_family_service.rb' }

      context 'when comment is expected' do
        let(:file_diff) do
          <<~DIFF.split("\n")
              scope :self_and_ancestors_not_aimed_for_deletion, -> do
                left_joins(:group)
                  .where(marked_for_deletion_at: nil)
          +       .where.not(Group.self_or_ancestors_deletion_schedule_subquery.exists)
                  .without_deleted
              end
          DIFF
        end

        specify do
          expect(bulk_database_actions).to receive(:markdown).with(comment_text.chomp, file: filename, line: 4)

          bulk_database_actions.add_suggestions_for(filename)
        end
      end

      context 'when no comment is expected' do
        let(:file_diff) do
          <<~DIFF.split("\n")
              scope :self_and_ancestors_not_aimed_for_deletion, -> do
                left_joins(:group)
                  .where(marked_for_deletion_at: nil)
                  .where.not(Group.self_or_ancestors_deletion_schedule_subquery.exists)
                  .without_deleted
              end
          +   validates :project_id, presence: true
          DIFF
        end

        specify do
          expect(bulk_database_actions).not_to receive(:markdown)

          bulk_database_actions.add_suggestions_for(filename)
        end
      end
    end
  end
end
