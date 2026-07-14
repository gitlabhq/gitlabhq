# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::WorkItemRelations::DestroyService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public) }
  let(:ids) { [user_created_relation.id] }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be_with_refind(:user_created_relation) do
    create(:merge_requests_closing_issues,
      merge_request: merge_request, issue: create(:issue, project: project),
      link_type: :mentioned, from_mr_description: false)
  end

  let_it_be_with_refind(:auto_closes_relation) do
    create(:merge_requests_closing_issues,
      merge_request: merge_request, issue: create(:issue, project: project),
      link_type: :closes, from_mr_description: true)
  end

  subject(:result) do
    described_class.new(merge_request: merge_request, current_user: user, ids: ids).execute
  end

  context 'when the user cannot admin work item relations' do
    let_it_be(:user) { create(:user) }

    it 'returns a forbidden error and deletes nothing', :aggregate_failures do
      expect { result }.not_to change { merge_request.merge_request_issues.count }

      expect(result).to be_error
      expect(result.reason).to eq(:forbidden)
    end
  end

  context 'when the user can admin work item relations' do
    it 'deletes the user-created relation and returns its id', :aggregate_failures do
      expect { result }.to change { merge_request.merge_request_issues.count }.by(-1)

      expect(result).to be_success
      expect(result.payload[:removed_ids]).to contain_exactly(user_created_relation.id)
    end

    context 'when targeting an auto-derived (from_mr_description) relation' do
      let(:ids) { [auto_closes_relation.id] }

      it 'does not delete it', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }
        expect(result.payload[:removed_ids]).to be_empty
      end
    end

    context 'when an id belongs to a different merge request' do
      let_it_be(:other_merge_request) { create(:merge_request, source_project: project, target_branch: 'other') }
      let_it_be(:foreign_relation) do
        create(:merge_requests_closing_issues,
          merge_request: other_merge_request, issue: create(:issue, project: project),
          link_type: :mentioned, from_mr_description: false)
      end

      let(:ids) { [foreign_relation.id] }

      it 'does not delete rows from another merge request', :aggregate_failures do
        expect { result }.not_to change { MergeRequestsClosingIssues.count }
        expect(result.payload[:removed_ids]).to be_empty
      end
    end

    context 'when a relation points to a work item the user cannot read' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:unreadable_relation) do
        create(:merge_requests_closing_issues,
          merge_request: merge_request, issue: create(:issue, project: private_project),
          link_type: :mentioned, from_mr_description: false)
      end

      let(:ids) { [unreadable_relation.id] }

      it 'does not delete it', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }
        expect(result.payload[:removed_ids]).to be_empty
      end
    end

    context 'when more than the allowed number of ids are given' do
      let(:ids) { (1..(described_class::MAX_RELATIONS + 1)).to_a }

      it 'returns an error and deletes nothing', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }

        expect(result).to be_error
        expect(result.reason).to eq(:bad_request)
      end
    end
  end
end
