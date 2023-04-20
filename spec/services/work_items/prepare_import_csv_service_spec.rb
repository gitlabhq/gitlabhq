# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::PrepareImportCsvService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:file) { double }
  let(:upload_service) { double }
  let(:uploader) { double }
  let(:upload) { double }

  let(:subject) do
    described_class.new(project, user, file: file).execute
  end

  context 'when file is uploaded correctly' do
    let(:upload_id) { 99 }

    before do
      mock_upload
    end

    it 'returns a success message' do
      result = subject

      expect(result[:status]).to eq(:success)
      expect(result[:message]).to eq(
        "Your work items are being imported. Once finished, you'll receive a confirmation email.")
    end

    it 'enqueues the ImportWorkItemsCsvWorker' do
      expect(WorkItems::ImportWorkItemsCsvWorker).to receive(:perform_async).with(user.id, project.id, upload_id)

      subject
    end
  end

  context 'when file upload fails' do
    before do
      mock_upload(false)
    end

    it 'returns an error message' do
      result = subject

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('File upload error.')
    end
  end
end
