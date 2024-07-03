# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Export work items', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:input) { { 'projectPath' => project.full_path } }
  let(:mutation) { graphql_mutation(:workItemExport, input) }
  let(:mutation_response) { graphql_mutation_response(:work_item_export) }

  context 'when user is not allowed to export work items' do
    let(:current_user) { guest }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when import_export_work_items_csv feature flag is disabled' do
    let(:current_user) { reporter }

    before do
      stub_feature_flags(import_export_work_items_csv: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['`import_export_work_items_csv` feature flag is disabled.']
  end

  context 'when user has permissions to export work items' do
    let(:current_user) { reporter }
    let(:input) do
      super().merge(
        'selectedFields' => %w[TITLE DESCRIPTION AUTHOR TYPE AUTHOR_USERNAME CREATED_AT],
        'authorUsername' => 'admin',
        'iids' => [work_item.iid.to_s],
        'state' => 'opened',
        'types' => 'TASK',
        'search' => 'any',
        'in' => 'TITLE'
      )
    end

    it 'schedules export job with given arguments', :aggregate_failures do
      expected_arguments = {
        selected_fields: ['title', 'description', 'author', 'type', 'author username', 'created_at'],
        author_username: 'admin',
        iids: [work_item.iid.to_s],
        state: 'opened',
        issue_types: ['task'],
        search: 'any',
        in: 'title'
      }

      expect(IssuableExportCsvWorker)
        .to receive(:perform_async).with(:work_item, current_user.id, project.id, expected_arguments)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['message']).to eq(
        'Your CSV export request has succeeded. The result will be emailed to ' \
        "#{reporter.notification_email_or_default}."
      )
      expect(mutation_response['errors']).to be_empty
    end
  end
end
