# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::Projects do
  include SentryClientHelpers

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:client) { ErrorTracking::SentryClient.new(sentry_url, token) }
  let(:projects_sample_response) do
    Gitlab::Utils.deep_indifferent_access(
      Gitlab::Json.parse(fixture_file('sentry/list_projects_sample_response.json'))
    )
  end

  shared_examples 'has correct return type' do |klass|
    it "returns objects of type #{klass}" do
      expect(subject).to all( be_a(klass) )
    end
  end

  shared_examples 'has correct length' do |length|
    it { expect(subject.length).to eq(length) }
  end

  describe '#projects' do
    let(:sentry_list_projects_url) { 'https://sentrytest.gitlab.com/api/0/projects/' }
    let(:sentry_api_response) { projects_sample_response }
    let!(:sentry_api_request) { stub_sentry_request(sentry_list_projects_url, body: sentry_api_response) }

    subject { client.projects }

    it_behaves_like 'calls sentry api'

    it_behaves_like 'has correct return type', Gitlab::ErrorTracking::Project
    it_behaves_like 'has correct length', 2

    context 'essential keys missing in API response' do
      let(:sentry_api_response) do
        projects_sample_response[0...1].map do |project|
          project.except(:slug)
        end
      end

      it 'raises exception' do
        expect { subject }.to raise_error(ErrorTracking::SentryClient::MissingKeysError, 'Sentry API response is missing keys. key not found: "slug"')
      end
    end

    context 'optional keys missing in sentry response' do
      let(:sentry_api_response) do
        projects_sample_response[0...1].map do |project|
          project[:organization].delete(:id)
          project.delete(:id)
          project.except(:status)
        end
      end

      it_behaves_like 'calls sentry api'

      it_behaves_like 'has correct return type', Gitlab::ErrorTracking::Project
      it_behaves_like 'has correct length', 1
    end

    context 'error object created from sentry response' do
      using RSpec::Parameterized::TableSyntax

      where(:sentry_project_object, :sentry_response) do
        :id                | :id
        :name              | :name
        :status            | :status
        :slug              | :slug
        :organization_name | [:organization, :name]
        :organization_id   | [:organization, :id]
        :organization_slug | [:organization, :slug]
      end

      with_them do
        it do
          expect(subject[0].public_send(sentry_project_object)).to(
            eq(sentry_api_response[0].dig(*sentry_response))
          )
        end
      end
    end

    context 'redirects' do
      let(:sentry_api_url) { sentry_list_projects_url }

      it_behaves_like 'no Sentry redirects'
    end

    context 'when exception is raised' do
      let(:sentry_request_url) { sentry_list_projects_url }

      it_behaves_like 'maps Sentry exceptions'
    end
  end
end
