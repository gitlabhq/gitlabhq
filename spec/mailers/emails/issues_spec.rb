# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Emails::Issues do
  include EmailSpec::Matchers

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end

  describe "#import_issues_csv_email" do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    subject { Notify.import_issues_csv_email(user.id, project.id, @results) }

    it "shows number of successful issues imported" do
      @results = { success: 165, error_lines: [], parse_error: false }

      expect(subject).to have_body_text "165 issues imported"
    end

    it "shows error when file is invalid" do
      @results = { success: 0, error_lines: [], parse_error: true }

      expect(subject).to have_body_text "Error parsing CSV"
    end

    it "shows line numbers with errors" do
      @results = { success: 0, error_lines: [23, 34, 58], parse_error: false }

      expect(subject).to have_body_text "23, 34, 58"
    end

    context 'with header and footer' do
      let(:results) { { success: 165, error_lines: [], parse_error: false } }

      subject { Notify.import_issues_csv_email(user.id, project.id, results) }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
    end
  end

  describe '#issues_csv_email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:project, path: 'myproject') }
    let(:export_status) { { truncated: false, rows_expected: 3, rows_written: 3 } }
    let(:attachment) { subject.attachments.first }

    subject { Notify.issues_csv_email(user, empty_project, "dummy content", export_status) }

    include_context 'gitlab email notification'

    it 'attachment has csv mime type' do
      expect(attachment.mime_type).to eq 'text/csv'
    end

    it 'generates a useful filename' do
      expect(attachment.filename).to include(Date.today.year.to_s)
      expect(attachment.filename).to include('issues')
      expect(attachment.filename).to include('myproject')
      expect(attachment.filename).to end_with('.csv')
    end

    it 'mentions number of issues and project name' do
      expect(subject).to have_content '3'
      expect(subject).to have_content empty_project.name
    end

    it "doesn't need to mention truncation by default" do
      expect(subject).not_to have_content 'truncated'
    end

    context 'when truncated' do
      let(:export_status) { { truncated: true, rows_expected: 12, rows_written: 10 } }

      it 'mentions that the csv has been truncated' do
        expect(subject).to have_content 'truncated'
      end

      it 'mentions the number of issues written and expected' do
        expect(subject).to have_content '10 of 12 issues'
      end
    end
  end
end
