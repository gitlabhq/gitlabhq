# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::Development, feature_category: :code_review_workflow do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :private, developers: developer) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let(:error_class) { ::Issuable::Callbacks::Base::Error }
  let(:current_user) { developer }
  let(:merge_request_ids) { [merge_request.id] }
  let(:params) { { merge_request_ids: merge_request_ids, link_type: 'related' } }
  let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

  describe '#before_create' do
    subject(:before_create) { service.before_create }

    it 'does not raise for an authorized related link' do
      expect { before_create }.not_to raise_error
    end

    context 'when the user cannot manage relations on the merge request' do
      let(:current_user) { create(:user) }

      it 'raises a widget error so work item creation is aborted' do
        expect { before_create }.to raise_error(error_class)
      end
    end

    context 'when link_type is mentioned' do
      let(:params) { { merge_request_ids: merge_request_ids, link_type: 'mentioned' } }

      it 'raises a widget error' do
        expect { before_create }
          .to raise_error(error_class, 'Mentioned relations are managed automatically and cannot be created.')
      end
    end

    context 'when there are no merge_request_ids in params' do
      let(:params) { {} }

      it 'does nothing' do
        expect { before_create }.not_to raise_error
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(explicit_mr_work_item_relations: false)
      end

      let(:current_user) { create(:user) }

      it 'does not validate (and does not raise) for flag-off merge requests' do
        expect { before_create }.not_to raise_error
      end
    end
  end

  describe '#after_save_commit' do
    subject(:development_callback) { service.after_save_commit }

    it 'links the work item to the merge request with the given link_type', :aggregate_failures do
      expect(::MergeRequests::WorkItemRelations::CreateService).to receive(:new).and_call_original

      expect { development_callback }.to change { merge_request.merge_request_issues.count }.by(1)

      relation = merge_request.merge_request_issues.find_by(issue_id: work_item.id)
      expect(relation.link_type).to eq('related')
      expect(relation.from_mr_description).to be(false)
    end

    context 'when link_type is not present' do
      let(:params) { { merge_request_ids: merge_request_ids } }

      it 'defaults to related' do
        development_callback

        expect(merge_request.merge_request_issues.find_by(issue_id: work_item.id).link_type).to eq('related')
      end
    end

    context 'when there are no merge_request_ids in params' do
      let(:params) { {} }

      it 'does nothing' do
        expect(::MergeRequests::WorkItemRelations::CreateService).not_to receive(:new)

        expect { development_callback }.not_to change { merge_request.merge_request_issues.count }
      end
    end

    context 'with multiple merge requests' do
      let_it_be(:other_merge_request) { create(:merge_request, source_project: project, source_branch: 'feature-2') }
      let(:merge_request_ids) { [merge_request.id, other_merge_request.id] }

      it 'links the work item to each merge request', :aggregate_failures do
        development_callback

        expect(merge_request.merge_request_issues.exists?(issue_id: work_item.id)).to be(true)
        expect(other_merge_request.merge_request_issues.exists?(issue_id: work_item.id)).to be(true)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(explicit_mr_work_item_relations: false)
      end

      it 'does not link the work item' do
        expect(::MergeRequests::WorkItemRelations::CreateService).not_to receive(:new)

        expect { development_callback }.not_to change { merge_request.merge_request_issues.count }
      end
    end

    context "when the feature flag is disabled for the work item's project" do
      let_it_be(:other_project) { create(:project, :repository, :private, developers: developer) }
      let_it_be(:other_work_item) { create(:work_item, :issue, project: other_project) }

      let(:service) { described_class.new(issuable: other_work_item, current_user: current_user, params: params) }

      before do
        stub_feature_flags(explicit_mr_work_item_relations: merge_request.project)
      end

      it 'does not link even when the merge request project has the flag on' do
        expect(::MergeRequests::WorkItemRelations::CreateService).not_to receive(:new)

        expect { development_callback }.not_to change { merge_request.merge_request_issues.count }
      end
    end

    context 'when a residual link failure occurs after the work item is committed' do
      let(:current_user) { create(:user) }

      it 'logs the error instead of raising, and creates no relation', :aggregate_failures do
        expect(service).to receive(:log_error).with(an_instance_of(String))

        expect { development_callback }.not_to raise_error
        expect(merge_request.merge_request_issues.where(issue_id: work_item.id)).to be_empty
      end
    end
  end
end
