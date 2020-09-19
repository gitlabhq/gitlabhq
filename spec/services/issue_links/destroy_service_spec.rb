# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::DestroyService do
  describe '#execute' do
    let(:project) { create(:project_empty_repo) }
    let(:user) { create(:user) }

    subject { described_class.new(issue_link, user).execute }

    context 'when successfully removes an issue link' do
      let(:issue_a) { create(:issue, project: project) }
      let(:issue_b) { create(:issue, project: project) }

      let!(:issue_link) { create(:issue_link, source: issue_a, target: issue_b) }

      before do
        project.add_reporter(user)
      end

      it 'removes related issue' do
        expect { subject }.to change(IssueLink, :count).from(1).to(0)
      end

      it 'creates notes' do
        # Two-way notes creation
        expect(SystemNoteService).to receive(:unrelate_issue)
                                       .with(issue_link.source, issue_link.target, user)
        expect(SystemNoteService).to receive(:unrelate_issue)
                                       .with(issue_link.target, issue_link.source, user)

        subject
      end

      it 'returns success message' do
        is_expected.to eq(message: 'Relation was removed', status: :success)
      end

      context 'target is an incident' do
        let(:issue_b) { create(:incident, project: project) }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_unrelate do
          let(:current_user) { user }
        end
      end
    end

    context 'when failing to remove an issue link' do
      let(:unauthorized_project) { create(:project) }
      let(:issue_a) { create(:issue, project: project) }
      let(:issue_b) { create(:issue, project: unauthorized_project) }

      let!(:issue_link) { create(:issue_link, source: issue_a, target: issue_b) }

      it 'does not remove relation' do
        expect { subject }.not_to change(IssueLink, :count).from(1)
      end

      it 'does not create notes' do
        expect(SystemNoteService).not_to receive(:unrelate_issue)
      end

      it 'returns error message' do
        is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
      end
    end
  end
end
