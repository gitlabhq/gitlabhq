# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/required_stops'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RequiredStops, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:warning_comment) { described_class::WARNING_COMMENT.chomp }

  subject(:required_stops) { fake_danger.new(helper: fake_helper) }

  before do
    allow(required_stops).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#add_comment_for_finalized_migrations' do
    let(:file_lines) { file_diff.map { |line| line.delete_prefix('+').delete_prefix('-') } }

    before do
      allow(required_stops.project_helper).to receive(:file_lines).and_return(file_lines)
      allow(required_stops.helper).to receive(:all_changed_files).and_return([filename])
      allow(required_stops.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    end

    shared_examples "adds comment to added migration finalizations" do
      context 'when model has a newly added migration finalization' do
        let(:file_diff) do
          [
            "+ def up",
            "+ finalize_background_migration(MIGRATION)",
            "+ end",
            "+ def up",
            "+ finalize_background_migration('MyMigration')",
            "+ end",
            "+ def up",
            "+ ensure_batched_background_migration_is_finished(",
            "+ end",
            "+ def up",
            "+ ensure_batched_background_migration_is_finished('MyMigration')",
            "+ end",
            "+ def up",
            "+ finalize_batched_background_migration(",
            "+ end",
            "+ def up",
            "+ finalize_batched_background_migration('MyMigration')",
            "+ end"
          ]
        end

        it 'adds comment at the correct line' do
          matching_line_numbers = [2, 5, 8, 11, 14, 17]
          matching_line_numbers.each do |line_number|
            expect(required_stops).to receive(:markdown).with("\n#{warning_comment}", file: filename, line: line_number)
          end

          required_stops.add_comment_for_finalized_migrations
        end
      end

      context 'when model does not have migration finalization statement' do
        let(:file_diff) do
          [
            "+ queue_batched_background_migration(",
            "- ensure_batched_background_migration_is_finished("
          ]
        end

        it 'does not add comment' do
          expect(required_stops).not_to receive(:markdown)

          required_stops.add_comment_for_finalized_migrations
        end
      end
    end

    context 'when model has a newly added migration finalization' do
      context 'with regular migration' do
        let(:filename) { 'db/migrate/my_migration.rb' }

        include_examples 'adds comment to added migration finalizations'
      end

      context 'with post migration' do
        let(:filename) { 'db/post_migrate/my_migration.rb' }

        include_examples 'adds comment to added migration finalizations'
      end
    end
  end
end
