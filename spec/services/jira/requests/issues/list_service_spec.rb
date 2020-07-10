# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Issues::ListService do
  let(:jira_service) { create(:jira_service) }
  let(:params) { {} }

  describe '#execute' do
    let(:service) { described_class.new(jira_service, params) }

    subject { service.execute }

    context 'without jira_service' do
      before do
        jira_service.update!(active: false)
      end

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'when jira_service is nil' do
      let(:jira_service) { nil }

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'with jira_service' do
      context 'when validations and params are ok' do
        let(:client) { double(options: { site: 'https://jira.example.com' }) }

        before do
          expect(service).to receive(:client).at_least(:once).and_return(client)
        end

        context 'when the request to Jira returns an error' do
          before do
            expect(client).to receive(:get).and_raise(Timeout::Error)
          end

          it 'returns an error response' do
            expect(subject.error?).to be_truthy
            expect(subject.message).to eq('Jira request error: Timeout::Error')
          end
        end

        context 'when the request does not return any values' do
          before do
            expect(client).to receive(:get).and_return([])
          end

          it 'returns a payload with no issues' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:issues]).to be_empty
            expect(payload[:is_last]).to be_truthy
          end
        end

        context 'when the request returns values' do
          before do
            expect(client).to receive(:get).and_return(
              {
                "total" => 375,
                "startAt" => 0,
                "issues" => [{ "key" => 'TST-1' }, { "key" => 'TST-2' }]
              }
            )
          end

          it 'returns a payload with jira issues' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:issues].map(&:key)).to eq(%w[TST-1 TST-2])
            expect(payload[:is_last]).to be_falsy
          end
        end

        context 'when using pagination parameters' do
          let(:params) { { page: 3, per_page: 20 } }

          it 'honors page and per_page' do
            expect(client).to receive(:get).with(include('startAt=40&maxResults=20')).and_return([])

            subject
          end
        end

        context 'without pagination parameters' do
          let(:params) { {} }

          it 'uses the default options' do
            expect(client).to receive(:get).with(include('startAt=0&maxResults=100'))

            subject
          end
        end
      end
    end
  end
end
