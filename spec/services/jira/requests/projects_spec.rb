# frozen_string_literal: true

require 'spec_helper'

describe Jira::Requests::Projects do
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
      context 'when limit is invalid' do
        let(:params) { { limit: 0 } }

        it 'returns a paylod with no projects returned' do
          expect(subject.payload[:projects]).to be_empty
        end
      end

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
            expect(subject.message).to eq('Timeout::Error')
          end
        end

        context 'when the request does not return any values' do
          before do
            expect(client).to receive(:get).and_return({ 'someKey' => 'value' })
          end

          it 'returns a paylod with no projects returned' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects]).to be_empty
            expect(payload[:is_last]).to be_truthy
          end
        end

        context 'when the request returns values' do
          before do
            expect(client).to receive(:get).and_return(
              { 'values' => %w(project1 project2), 'isLast' => false }
            )
            expect(JIRA::Resource::Project).to receive(:build).with(client, 'project1').and_return('jira_project1')
            expect(JIRA::Resource::Project).to receive(:build).with(client, 'project2').and_return('jira_project2')
          end

          it 'returns a paylod with jira projets' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects]).to eq(%w(jira_project1 jira_project2))
            expect(payload[:is_last]).to be_falsey
          end
        end
      end
    end
  end
end
