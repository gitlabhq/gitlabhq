# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ExportCsvService do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:csv) { CSV.parse(subject.csv_data, headers: true).first }

  subject { described_class.new(MergeRequest.where(id: merge_request.id), merge_request.project) }

  describe 'csv_data' do
    it 'contains the correct information', :aggregate_failures do
      expect(csv['MR IID']).to eq(merge_request.iid.to_s)
      expect(csv['Title']).to eq(merge_request.title)
      expect(csv['State']).to eq(merge_request.state)
      expect(csv['Description']).to eq(merge_request.description)
      expect(csv['Source Branch']).to eq(merge_request.source_branch)
      expect(csv['Target Branch']).to eq(merge_request.target_branch)
      expect(csv['Source Project ID']).to eq(merge_request.source_project_id.to_s)
      expect(csv['Target Project ID']).to eq(merge_request.target_project_id.to_s)
      expect(csv['Author']).to eq(merge_request.author.name)
      expect(csv['Author Username']).to eq(merge_request.author.username)
    end

    describe 'assignees' do
      context 'when assigned' do
        let_it_be(:merge_request) { create(:merge_request, assignees: create_list(:user, 2)) }

        it 'contains the names of assignees' do
          expect(csv['Assignees'].split(', ')).to match_array(merge_request.assignees.map(&:name))
        end

        it 'contains the usernames of assignees' do
          expect(csv['Assignee Usernames'].split(', ')).to match_array(merge_request.assignees.map(&:username))
        end
      end

      context 'when not assigned' do
        it 'returns empty strings' do
          expect(csv['Assignees']).to eq('')
          expect(csv['Assignee Usernames']).to eq('')
        end
      end
    end

    describe 'approvers' do
      context 'when approved' do
        let_it_be(:merge_request) { create(:merge_request) }

        let(:approvers) { create_list(:user, 2) }

        before do
          merge_request.approved_by_users = approvers
        end

        it 'contains the names of approvers separated by a comma' do
          expect(csv['Approvers'].split(', ')).to contain_exactly(approvers[0].name, approvers[1].name)
        end

        it 'contains the usernames of approvers separated by a comma' do
          expect(csv['Approver Usernames'].split(', ')).to contain_exactly(approvers[0].username, approvers[1].username)
        end
      end

      context 'when not approved' do
        it 'returns empty strings' do
          expect(csv['Approvers']).to eq('')
          expect(csv['Approver Usernames']).to eq('')
        end
      end
    end

    describe 'merged user' do
      context 'MR is merged' do
        let_it_be(:merge_request) { create(:merge_request, :merged, :with_merged_metrics) }

        it 'is merged' do
          expect(csv['State']).to eq('merged')
        end

        it 'has a merged user' do
          expect(csv['Merged User']).to eq(merge_request.metrics.merged_by.name)
          expect(csv['Merged Username']).to eq(merge_request.metrics.merged_by.username)
        end
      end

      context 'MR is not merged' do
        it 'returns empty strings' do
          expect(csv['Merged User']).to eq('')
          expect(csv['Merged Username']).to eq('')
        end
      end
    end

    describe 'milestone' do
      context 'milestone is assigned' do
        let_it_be(:merge_request) { create(:merge_request) }
        let_it_be(:milestone) { create(:milestone, :active, project: merge_request.project) }

        before do
          merge_request.update!(milestone_id: milestone.id)
        end

        it 'contains the milestone ID' do
          expect(csv['Milestone ID']).to eq(merge_request.milestone.id.to_s)
        end
      end

      context 'no milestone is assigned' do
        it 'returns an empty string' do
          expect(csv['Milestone ID']).to eq('')
        end
      end
    end
  end
end
