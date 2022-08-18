# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a timelog' do
  include GraphqlHelpers

  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:time_spent) { '1h' }

  let(:current_user) { nil }
  let(:users_container) { project }
  let(:mutation) do
    graphql_mutation(:timelogCreate, {
      'time_spent' => time_spent,
      'spent_at' => '2022-07-08',
      'summary' => 'Test summary',
      'issuable_id' => issuable.to_global_id.to_s
    })
  end

  let(:mutation_response) { graphql_mutation_response(:timelog_create) }

  context 'when issuable is an Issue' do
    let_it_be(:issuable) { create(:issue, project: project) }

    it_behaves_like 'issuable supports timelog creation mutation'
  end

  context 'when issuable is a MergeRequest' do
    let_it_be(:issuable) { create(:merge_request, source_project: project) }

    it_behaves_like 'issuable supports timelog creation mutation'
  end

  context 'when issuable is a WorkItem' do
    let_it_be(:issuable) { create(:work_item, project: project, title: 'WorkItem') }

    it_behaves_like 'issuable supports timelog creation mutation'
  end

  context 'when issuable is an Incident' do
    let_it_be(:issuable) { create(:incident, project: project) }

    it_behaves_like 'issuable supports timelog creation mutation'
  end
end
