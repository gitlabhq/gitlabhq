# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Projects::ListService, feature_category: :groups_and_projects do
  include AfterNextHelpers

  let(:jira_integration) { create(:jira_integration) }
  let(:params) { {} }

  describe '#execute' do
    let(:service) { described_class.new(jira_integration, params) }

    subject { service.execute }

    context 'without jira_integration' do
      before do
        jira_integration.update!(active: false)
      end

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'when jira_integration is nil' do
      let(:jira_integration) { nil }

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'with jira_integration' do
      context 'when validations and params are ok' do
        let(:response_headers) { { 'content-type' => 'application/json' } }
        let(:response_body) { [].to_json }
        let(:expected_url_pattern) { %r{.*jira.example.com/rest/api/2/project} }

        before do
          stub_request(:get, expected_url_pattern).to_return(status: 200, body: response_body, headers: response_headers)
        end

        it_behaves_like 'a service that handles Jira API errors'

        context 'when jira runs on a subpath' do
          let(:jira_integration) { create(:jira_integration, url: 'http://jira.example.com/jira') }
          let(:expected_url_pattern) { %r{.*jira.example.com/jira/rest/api/2/project} }

          it 'takes the subpath into account' do
            expect(subject.success?).to be_truthy
          end
        end

        context 'when the request does not return any values' do
          let(:response_body) { [].to_json }

          it 'returns a paylod with no projects returned' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects]).to be_empty
            expect(payload[:is_last]).to be_truthy
          end
        end

        context 'when the request returns values' do
          let(:response_body) { [{ 'key' => 'pr1', 'name' => 'First Project' }, { 'key' => 'pr2', 'name' => 'Second Project' }].to_json }

          it 'returns a paylod with Jira projects' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects].map(&:key)).to eq(%w[pr1 pr2])
            expect(payload[:is_last]).to be_truthy
          end

          context 'when filtering projects by name' do
            let(:params) { { query: 'first' } }

            it 'returns a paylod with Jira procjets' do
              payload = subject.payload

              expect(subject.success?).to be_truthy
              expect(payload[:projects].map(&:key)).to eq(%w[pr1])
              expect(payload[:is_last]).to be_truthy
            end
          end
        end
      end
    end
  end
end
