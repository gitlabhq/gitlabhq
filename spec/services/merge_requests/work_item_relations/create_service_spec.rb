# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::WorkItemRelations::CreateService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public) }
  let(:target_work_items) { [work_item] }
  let(:link_type) { :mentioned }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }
  let_it_be(:other_work_item) { create(:work_item, :issue, project: project) }

  subject(:result) do
    described_class.new(
      merge_request: merge_request,
      current_user: user,
      target_work_items: target_work_items,
      link_type: link_type
    ).execute
  end

  context 'when the user cannot admin work item relations' do
    let_it_be(:user) { create(:user) }

    it 'returns a forbidden error and creates nothing', :aggregate_failures do
      expect { result }.not_to change { merge_request.merge_request_issues.count }

      expect(result).to be_error
      expect(result.reason).to eq(:forbidden)
    end
  end

  context 'when the user can admin work item relations' do
    it 'creates a user-created relation with the given link_type', :aggregate_failures do
      expect { result }.to change { merge_request.merge_request_issues.count }.by(1)

      relation = merge_request.merge_request_issues.order(:id).last
      expect(result).to be_success
      expect(relation).to have_attributes(
        issue_id: work_item.id,
        link_type: 'mentioned',
        from_mr_description: false,
        project_id: merge_request.project_id
      )
    end

    context 'with link_type closes' do
      let(:link_type) { :closes }

      it 'creates a manual closes relation (from_mr_description false)', :aggregate_failures do
        result

        relation = merge_request.merge_request_issues.order(:id).last
        expect(relation.link_type).to eq('closes')
        expect(relation.from_mr_description).to be(false)
      end
    end

    context 'when an auto-derived (from_mr_description) closes row already exists for the work item' do
      let(:link_type) { :closes }

      let_it_be(:auto_closes_relation) do
        create(:merge_requests_closing_issues,
          merge_request: merge_request, issue_id: work_item.id, link_type: :closes, from_mr_description: true)
      end

      it 'leaves the auto-derived row untouched and reuses it (idempotent)', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }

        expect(auto_closes_relation.reload.from_mr_description).to be(true)
        expect(result).to be_success
        expect(result.payload[:work_item_relations]).to contain_exactly(auto_closes_relation)
        expect(result.payload[:errors]).to be_empty
      end
    end

    context 'when the relation already exists' do
      before do
        create(:merge_requests_closing_issues,
          merge_request: merge_request, issue: work_item, link_type: :mentioned, from_mr_description: false)
      end

      it 'is idempotent and does not duplicate the row', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }
        expect(result).to be_success
      end
    end

    context 'with multiple target work items' do
      let(:target_work_items) { [work_item, other_work_item] }

      it 'creates a relation per work item', :aggregate_failures do
        expect { result }.to change { merge_request.merge_request_issues.count }.by(2)
        expect(result).to be_success
      end
    end

    context 'when a target work item is not readable by the user' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:unreadable_work_item) { create(:work_item, :issue, project: private_project) }

      let(:target_work_items) { [work_item, unreadable_work_item] }

      it 'only links the readable work items', :aggregate_failures do
        expect { result }.to change { merge_request.merge_request_issues.count }.by(1)

        issue_ids = merge_request.merge_request_issues.pluck(:issue_id)
        expect(issue_ids).to contain_exactly(work_item.id)
      end
    end

    context 'when no target work item is readable' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:unreadable_work_item) { create(:work_item, :issue, project: private_project) }

      let(:target_work_items) { [unreadable_work_item] }

      it 'returns an error and creates nothing', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }

        expect(result).to be_error
        expect(result.reason).to eq(:unprocessable_entity)
      end
    end

    it 'returns the created relations and an empty errors list on success', :aggregate_failures do
      expect(result.payload[:work_item_relations].map(&:issue_id)).to contain_exactly(work_item.id)
      expect(result.payload[:errors]).to be_empty
    end

    context 'when every work item fails to link' do
      before do
        allow_next_instance_of(MergeRequestsClosingIssues) do |relation|
          allow(relation).to receive(:save) do
            relation.errors.add(:base, 'boom')
            false
          end
        end
      end

      it 'returns an error with the per-item reason instead of an empty success', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }

        expect(result).to be_error
        expect(result.reason).to eq(:unprocessable_entity)
        expect(result.payload[:work_item_relations]).to be_empty
        expect(result.payload[:errors].first).to include(work_item.to_reference).and include('boom')
      end
    end

    context 'when some work items link and others fail' do
      let(:target_work_items) { [work_item, other_work_item] }

      before do
        # Fail only work_item's relation; other_work_item saves for real.
        allow_next_instance_of(MergeRequestsClosingIssues) do |relation|
          allow(relation).to receive(:save).and_wrap_original do |original|
            next original.call unless relation.issue_id == work_item.id

            relation.errors.add(:base, 'boom')
            false
          end
        end
      end

      it 'returns success with the linked relations and the per-item errors', :aggregate_failures do
        expect { result }.to change { merge_request.merge_request_issues.count }.by(1)

        expect(result).to be_success
        expect(result.payload[:work_item_relations].map(&:issue_id)).to contain_exactly(other_work_item.id)
        expect(result.payload[:errors].first).to include(work_item.to_reference)
      end
    end

    context 'when more than the allowed number of work items are given' do
      let(:target_work_items) { Array.new(described_class::MAX_RELATIONS + 1) { work_item } }

      it 'returns an error and links nothing', :aggregate_failures do
        expect { result }.not_to change { merge_request.merge_request_issues.count }

        expect(result).to be_error
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when the row is inserted concurrently (RecordNotUnique)' do
      let(:link_type) { :closes }

      let_it_be(:concurrent_relation) do
        create(:merge_requests_closing_issues,
          merge_request: merge_request, issue: work_item, link_type: :closes, from_mr_description: true)
      end

      before do
        allow_next_instance_of(MergeRequestsClosingIssues) do |relation|
          allow(relation).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
        end
      end

      it 'reuses the existing row instead of raising', :aggregate_failures do
        expect { result }.not_to raise_error
        expect(result).to be_success
        expect(result.payload[:work_item_relations]).to contain_exactly(concurrent_relation)
        expect(result.payload[:errors]).to be_empty
      end
    end
  end
end
