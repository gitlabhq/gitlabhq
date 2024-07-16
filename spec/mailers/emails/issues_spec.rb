# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Issues, feature_category: :team_planning do
  include EmailSpec::Matchers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end

  describe "#import_issues_csv_email" do
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

    it "shows issuable errors with column" do
      @results = { success: 0, error_lines: [], parse_error: false,
                   preprocess_errors:
                     { milestone_errors: { missing: { header: 'Milestone', titles: %w[15.10 15.11] } } } }

      expect(subject).to have_body_text(
        'Could not find the following milestone values in ' \
          "#{project.full_name} or its parent groups: 15.10, 15.11"
      )
    end

    context 'with header and footer' do
      let(:results) { { success: 165, error_lines: [], parse_error: false } }

      subject { Notify.import_issues_csv_email(user.id, project.id, results) }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
    end
  end

  describe '#issues_csv_email' do
    let(:empty_project) { create(:project, path: 'myproject') }
    let(:export_status) { { truncated: false, rows_expected: 3, rows_written: 3 } }
    let(:attachment) { subject.attachments.first }

    subject { Notify.issues_csv_email(user, empty_project, "dummy content", export_status) }

    it_behaves_like 'export csv email', 'issues'
  end
end
