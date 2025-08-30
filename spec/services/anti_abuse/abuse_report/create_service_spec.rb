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

  describe '#execute' do
    context 'when creation is successful' do
      it 'creates an AbuseReport correctly' do
        expect { service_response }.to change { AbuseReport.count }.by(1)

        abuse_report = AbuseReport.last

        expect(abuse_report.user).to eq(user)
        expect(abuse_report.reporter).to eq(reporter)
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

      it 'does not create an AbuseReport' do
        expect { service_response }.not_to change { AbuseReport.count }
      end

      it 'returns an error response' do
        expect(service_response).to be_error
        expect(service_response.message).to eq('AbuseReport record was not created')
      end
    end
  end
end
