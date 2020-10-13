# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Projects::ListService do
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
            expect(Gitlab::ProjectServiceLogger).to receive(:error).with(
              hash_including(
                error: hash_including(:exception_class, :exception_message, :exception_backtrace)))
              .and_call_original
            expect(subject.error?).to be_truthy
            expect(subject.message).to eq('Jira request error: Timeout::Error')
          end
        end

        context 'when the request does not return any values' do
          before do
            expect(client).to receive(:get).and_return([])
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
            expect(client).to receive(:get).and_return([{ 'key' => 'pr1', 'name' => 'First Project' }, { 'key' => 'pr2', 'name' => 'Second Project' }])
          end

          it 'returns a paylod with Jira projects' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects].map(&:key)).to eq(%w(pr1 pr2))
            expect(payload[:is_last]).to be_truthy
          end

          context 'when filtering projects by name' do
            let(:params) { { query: 'first' } }

            it 'returns a paylod with Jira procjets' do
              payload = subject.payload

              expect(subject.success?).to be_truthy
              expect(payload[:projects].map(&:key)).to eq(%w(pr1))
              expect(payload[:is_last]).to be_truthy
            end
          end
        end
      end
    end
  end
end
