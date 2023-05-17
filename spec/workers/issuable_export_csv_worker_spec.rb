# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableExportCsvWorker, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }
  let(:params) { {} }

  subject { described_class.new.perform(issuable_type, user.id, project.id, params) }

  context 'when issuable type is Issue' do
    let(:issuable_type) { :issue }

    it 'emails a CSV' do
      expect { subject }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'ensures that project_id is passed to issues_finder' do
      expect(IssuesFinder).to receive(:new).with(anything, hash_including(project_id: project.id)).and_call_original

      subject
    end

    it 'defines the loggable_arguments' do
      expect(described_class.loggable_arguments).to match_array([0, 1, 2, 3])
    end

    it 'removes sort parameter' do
      expect(IssuesFinder).to receive(:new).with(anything, hash_not_including(:sort)).and_call_original

      subject
    end

    it 'calls the issue export service' do
      expect(Issues::ExportCsvService).to receive(:new).once.and_call_original

      subject
    end

    context 'with params' do
      let(:params) { { 'test_key' => true, 'not' => { 'label_name' => ['SomeLabel'] } } }

      it 'allows symbol access for IssuesFinder' do
        expect(IssuesFinder).to receive(:new).and_wrap_original do |method, user, params|
          expect(params[:test_key]).to eq(true)
          expect(params[:not][:label_name]).to eq(['SomeLabel'])

          method.call(user, params)
        end

        subject
      end
    end
  end

  shared_examples 'export with selected fields' do
    let(:selected_fields) { %w[Title Description'] }

    it 'calls the export service with selected fields' do
      params[:selected_fields] = selected_fields

      expect(export_service)
        .to receive(:new).with(anything, project, selected_fields).once.and_call_original

      subject
    end
  end

  context 'when issuable type is MergeRequest' do
    let(:issuable_type) { :merge_request }

    it 'emails a CSV' do
      expect { subject }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'calls the MR export service' do
      expect(MergeRequests::ExportCsvService).to receive(:new).with(anything, project, []).once.and_call_original

      subject
    end

    it 'calls the MergeRequest finder' do
      expect(MergeRequestsFinder).to receive(:new).once.and_call_original

      subject
    end

    it_behaves_like 'export with selected fields' do
      let(:export_service) { MergeRequests::ExportCsvService }
    end
  end

  context 'for type WorkItem' do
    let(:issuable_type) { :work_item }

    it 'emails a CSV' do
      expect { subject }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'calls the work item export service' do
      expect(WorkItems::ExportCsvService).to receive(:new).with(anything, project, []).once.and_call_original

      subject
    end

    it 'calls the WorkItemsFinder' do
      expect(WorkItems::WorkItemsFinder).to receive(:new).once.and_call_original

      subject
    end

    it_behaves_like 'export with selected fields' do
      let(:export_service) { WorkItems::ExportCsvService }
    end
  end

  context 'when issuable type is User' do
    let(:issuable_type) { :user }

    it { expect { subject }.to raise_error(ArgumentError) }
  end
end
