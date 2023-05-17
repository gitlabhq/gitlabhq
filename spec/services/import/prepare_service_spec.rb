# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PrepareService, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:file) { double }
  let(:upload_service) { double }
  let(:uploader) { double }
  let(:upload) { double }

  let(:service) { described_class.new(project, user, file: file) }

  subject { service.execute }

  context 'when file is uploaded correctly' do
    let(:upload_id) { 99 }

    before do
      mock_upload
    end

    it 'raises NotImplemented error for worker' do
      expect { subject }.to raise_error(NotImplementedError)
    end

    context 'when a job is enqueued' do
      before do
        worker = double

        allow(service).to receive(:worker).and_return(worker)
        allow(worker).to receive(:perform_async)
      end

      it 'raises NotImplemented error for success_message when a job is enqueued' do
        expect { subject }.to raise_error(NotImplementedError)
      end

      it 'returns a success respnse when a success_message is implemented' do
        message = 'It works!'

        allow(service).to receive(:success_message).and_return(message)

        result = subject

        expect(result).to be_success
        expect(result.message).to eq(message)
      end
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
