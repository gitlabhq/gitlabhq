# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::AbuseReport::CreateService, feature_category: :insider_threat do
  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:params) do
    {
      user: user,
      reporter: reporter,
      category: 'spam',
      message: 'This user is a spammer.'
    }
  end

  subject(:service_response) { described_class.new(params).execute }

  shared_examples 'returning an error' do
    it 'does not create an AbuseReport' do
      expect { service_response }.not_to change { AbuseReport.count }
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq(error_message)
    end
  end

  describe '#execute' do
    context 'when creation is successful' do
      it 'creates an AbuseReport correctly' do
        expect { service_response }.to change { AbuseReport.count }.by(1)

        abuse_report = AbuseReport.last

        expect(abuse_report.user).to eq(user)
        expect(abuse_report.reporter).to eq(reporter)
        expect(abuse_report.organization).to eq(reporter.organization)
        expect(abuse_report.category).to eq('spam')
        expect(abuse_report.message).to eq('This user is a spammer.')
      end

      it 'returns a successful response with payload' do
        expect(service_response).to be_success
        expect(service_response.payload).to be_a(AbuseReport)
      end
    end

    context 'when creation fails' do
      before do
        params.delete(:user) # user is required
      end

      let(:error_message) { 'AbuseReport record was not created' }

      it_behaves_like 'returning an error'
    end

    context 'with invalid params' do
      context 'when reporter param is missing' do
        let(:error_message) { 'Reporter param must be a valid User' }

        before do
          params.delete(:reporter)
        end

        it_behaves_like 'returning an error'
      end

      context 'when reporter param is invalid' do
        let(:error_message) { 'Reporter param must be a valid User' }

        before do
          params[:reporter] = 'invalid'
        end

        it_behaves_like 'returning an error'
      end
    end
  end
end
