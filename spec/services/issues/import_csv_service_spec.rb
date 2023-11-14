# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ImportCsvService, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:assignee) { create(:user, username: 'csv_assignee') }
  let(:file) { fixture_file_upload('spec/fixtures/csv_complex.csv') }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  let!(:test_milestone) { create(:milestone, project: project, title: '15.10') }

  include_examples 'issuable import csv service', 'issue' do
    let(:issuables) { project.issues }
    let(:email_method) { :import_issues_csv_email }
  end

  describe '#execute' do
    subject { service.execute }

    it_behaves_like 'performs a spam check', true

    it 'sets all issueable attributes and executes quick actions' do
      project.add_developer(user)
      project.add_developer(assignee)

      expect { subject }.to change { issuables.count }.by 3

      expect(issuables.reload).to include(
        have_attributes(
          title: 'Title with quote"',
          description: 'Description',
          time_estimate: 3600,
          assignees: include(assignee),
          due_date: Date.new(2022, 6, 28),
          milestone_id: test_milestone.id
        )
      )
    end

    context 'when user is an admin' do
      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it_behaves_like 'performs a spam check', false
    end
  end
end
