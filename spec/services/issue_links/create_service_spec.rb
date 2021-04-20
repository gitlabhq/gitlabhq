# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::CreateService do
  describe '#execute' do
    let(:namespace) { create :namespace }
    let(:project) { create :project, namespace: namespace }
    let(:issue) { create :issue, project: project }
    let(:user) { create :user }
    let(:params) do
      {}
    end

    before do
      project.add_developer(user)
    end

    subject { described_class.new(issue, user, params).execute }

    context 'when the reference list is empty' do
      let(:params) do
        { issuable_references: [] }
      end

      it 'returns error' do
        is_expected.to eq(message: 'No matching issue found. Make sure that you are adding a valid issue URL.', status: :error, http_status: 404)
      end
    end

    context 'when Issue not found' do
      let(:params) do
        { issuable_references: ["##{non_existing_record_iid}"] }
      end

      it 'returns error' do
        is_expected.to eq(message: 'No matching issue found. Make sure that you are adding a valid issue URL.', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change(IssueLink, :count)
      end
    end

    context 'when user has no permission to target project Issue' do
      let(:target_issuable) { create :issue }

      let(:params) do
        { issuable_references: [target_issuable.to_reference(project)] }
      end

      it 'returns error' do
        target_issuable.project.add_guest(user)

        is_expected.to eq(message: 'No matching issue found. Make sure that you are adding a valid issue URL.', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change(IssueLink, :count)
      end
    end

    context 'source and target are the same issue' do
      let(:params) do
        { issuable_references: [issue.to_reference] }
      end

      it 'does not create notes' do
        expect(SystemNoteService).not_to receive(:relate_issue)

        subject
      end

      it 'no relationship is created' do
        expect { subject }.not_to change(IssueLink, :count)
      end
    end

    context 'when there is an issue to relate' do
      let(:issue_a) { create :issue, project: project }
      let(:another_project) { create :project, namespace: project.namespace }
      let(:another_project_issue) { create :issue, project: another_project }

      let(:issue_a_ref) { issue_a.to_reference }
      let(:another_project_issue_ref) { another_project_issue.to_reference(project) }

      let(:params) do
        { issuable_references: [issue_a_ref, another_project_issue_ref] }
      end

      before do
        another_project.add_developer(user)
      end

      it 'creates relationships' do
        expect { subject }.to change(IssueLink, :count).from(0).to(2)

        expect(IssueLink.find_by!(target: issue_a)).to have_attributes(source: issue, link_type: 'relates_to')
        expect(IssueLink.find_by!(target: another_project_issue)).to have_attributes(source: issue, link_type: 'relates_to')
      end

      it 'returns success status' do
        is_expected.to eq(status: :success)
      end

      it 'creates notes' do
        # First two-way relation notes
        expect(SystemNoteService).to receive(:relate_issue)
          .with(issue, issue_a, user)
        expect(SystemNoteService).to receive(:relate_issue)
          .with(issue_a, issue, user)

        # Second two-way relation notes
        expect(SystemNoteService).to receive(:relate_issue)
          .with(issue, another_project_issue, user)
        expect(SystemNoteService).to receive(:relate_issue)
          .with(another_project_issue, issue, user)

        subject
      end

      context 'issue is an incident' do
        let(:issue) { create(:incident, project: project) }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_relate do
          let(:current_user) { user }
        end
      end
    end

    context 'when reference of any already related issue is present' do
      let(:issue_a) { create :issue, project: project }
      let(:issue_b) { create :issue, project: project }
      let(:issue_c) { create :issue, project: project }

      before do
        create :issue_link, source: issue, target: issue_b, link_type: IssueLink::TYPE_RELATES_TO
        create :issue_link, source: issue, target: issue_c, link_type: IssueLink::TYPE_RELATES_TO
      end

      let(:params) do
        {
          issuable_references: [
            issue_a.to_reference,
            issue_b.to_reference,
            issue_c.to_reference
          ],
          link_type: IssueLink::TYPE_RELATES_TO
        }
      end

      it 'creates notes only for new relations' do
        expect(SystemNoteService).to receive(:relate_issue).with(issue, issue_a, anything)
        expect(SystemNoteService).to receive(:relate_issue).with(issue_a, issue, anything)
        expect(SystemNoteService).not_to receive(:relate_issue).with(issue, issue_b, anything)
        expect(SystemNoteService).not_to receive(:relate_issue).with(issue_b, issue, anything)
        expect(SystemNoteService).not_to receive(:relate_issue).with(issue, issue_c, anything)
        expect(SystemNoteService).not_to receive(:relate_issue).with(issue_c, issue, anything)

        subject
      end
    end

    context 'when there are invalid references' do
      let(:issue_a) { create :issue, project: project }

      let(:params) do
        { issuable_references: [issue.to_reference, issue_a.to_reference] }
      end

      it 'creates links only for valid references' do
        expect { subject }.to change { IssueLink.count }.by(1)
      end

      it 'returns error status' do
        expect(subject).to eq(
          status: :error,
          http_status: 422,
          message: "#{issue.to_reference} cannot be added: cannot be related to itself"
        )
      end
    end
  end
end
