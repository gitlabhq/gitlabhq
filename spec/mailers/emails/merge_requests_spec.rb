# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::MergeRequests do
  include EmailSpec::Matchers

  let_it_be(:recipient) { create(:user) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee, reload: true) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
  let_it_be(:reviewer, reload: true) { create(:user, email: 'reviewer@example.com', name: 'Jane Doe') }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) do
    create(:merge_request, source_project: project,
                           target_project: project,
                           author: current_user,
                           assignees: [assignee],
                           reviewers: [reviewer],
                           description: 'Awesome description')
  end

  describe "#merge_when_pipeline_succeeds_email" do
    let(:title) { "Merge request #{merge_request.to_reference} was scheduled to merge after pipeline succeeds by #{current_user.name}" }

    subject { Notify.merge_when_pipeline_succeeds_email(recipient.id, merge_request.id, current_user.id) }

    it "has required details" do
      aggregate_failures do
        expect(subject).to have_content title
        expect(subject).to have_content merge_request.to_reference
        expect(subject).to have_content current_user.name
        expect(subject.html_part).to have_content(assignee.name)
        expect(subject.text_part).to have_content(assignee.name)
        expect(subject.html_part).to have_content(reviewer.name)
        expect(subject.text_part).to have_content(reviewer.name)
      end
    end
  end

  describe "#resolved_all_discussions_email" do
    subject { Notify.resolved_all_discussions_email(recipient.id, merge_request.id, current_user.id) }

    it "includes the name of the resolver" do
      expect(subject).to have_body_text current_user.name
    end
  end

  describe '#merge_requests_csv_email' do
    let(:merge_requests) { create_list(:merge_request, 10) }
    let(:export_status) do
      {
        rows_expected: 10,
        rows_written: 10,
        truncated: false
      }
    end

    let(:csv_data) { MergeRequests::ExportCsvService.new(MergeRequest.all, project).csv_data }

    subject { Notify.merge_requests_csv_email(recipient, project, csv_data, export_status) }

    it { expect(subject.subject).to eq("#{project.name} | Exported merge requests") }
    it { expect(subject.to).to contain_exactly(recipient.notification_email_for(project.group)) }
    it { expect(subject.html_part).to have_content("Your CSV export of 10 merge requests from project") }
    it { expect(subject.text_part).to have_content("Your CSV export of 10 merge requests from project") }

    context 'when truncated' do
      let(:export_status) do
        {
            rows_expected: 10,
            rows_written: 10,
            truncated: true
        }
      end

      it { expect(subject).to have_content('attachment has been truncated to avoid exceeding the maximum allowed attachment size of 15 MB.') }
    end
  end
end
