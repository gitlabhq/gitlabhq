# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::FogbugzService, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:base_uri) { "https://test:7990" }
  let(:token) { "asdasd12345" }
  let(:repo_id) { "fogbugz_id" }
  let(:repo) { instance_double(Gitlab::FogbugzImport::Repository, name: 'test', raw_data: nil) }

  let(:client) { instance_double(Gitlab::FogbugzImport::Client) }
  let(:credentials) { { uri: base_uri, token: token } }
  let(:params) { { repo_id: repo_id } }

  subject { described_class.new(client, user, params) }

  before do
    allow(subject).to receive(:authorized?).and_return(true)
    stub_application_setting(import_sources: ['fogbugz'])
  end

  context 'when no repo is found' do
    before do
      allow(client).to receive(:repo).with(repo_id).and_return(nil)
    end

    it 'returns an error' do
      result = subject.execute(credentials)

      expect(result).to include(
        message: "Project #{repo_id} could not be found",
        status: :error,
        http_status: :unprocessable_entity
      )
    end
  end

  context 'when import source is disabled' do
    before do
      stub_application_setting(import_sources: nil)
      allow(client).to receive(:repo).with(repo_id).and_return(repo)
    end

    it 'returns forbidden' do
      result = subject.execute(credentials)

      expect(result).to include(
        status: :error,
        http_status: :forbidden
      )
    end
  end

  context 'when user is unauthorized' do
    before do
      allow(subject).to receive(:authorized?).and_return(false)
    end

    it 'returns an error' do
      result = subject.execute(credentials)

      expect(result).to include(
        message: "You don't have permissions to import this project",
        status: :error,
        http_status: :unauthorized
      )
    end
  end

  context 'verify url' do
    shared_examples 'denies local request' do
      before do
        allow(client).to receive(:repo).with(repo_id).and_return(repo)
      end

      it 'does not allow requests' do
        result = subject.execute(credentials)
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include("Invalid URL:")
      end
    end

    context 'when host is localhost' do
      let(:base_uri) { 'http://localhost:3000' }

      include_examples 'denies local request'
    end

    context 'when host is on local network' do
      let(:base_uri) { 'https://192.168.0.191' }

      include_examples 'denies local request'
    end

    context 'when host is ftp protocol' do
      let(:base_uri) { 'ftp://testing' }

      include_examples 'denies local request'
    end
  end

  context 'when import starts successfully' do
    before do
      allow(client).to receive(:repo).with(repo_id).and_return(
        instance_double(Gitlab::FogbugzImport::Repository, name: 'test', raw_data: nil)
      )
    end

    it 'returns success' do
      result = subject.execute(credentials)

      expect(result[:status]).to eq(:success)
      expect(result[:project].name).to eq('test')
    end
  end

  context 'when import fails to start' do
    let(:error_messages_array) { instance_double(Array, join: "something went wrong") }
    let(:errors_double) { instance_double(ActiveModel::Errors, full_messages: error_messages_array, :[] => nil) }
    let(:project_double) { instance_double(Project, persisted?: false, errors: errors_double) }
    let(:project_creator) { instance_double(Gitlab::FogbugzImport::ProjectCreator, execute: project_double) }

    before do
      allow(Gitlab::FogbugzImport::ProjectCreator).to receive(:new).and_return(project_creator)
      allow(client).to receive(:repo).with(repo_id).and_return(
        instance_double(Gitlab::FogbugzImport::Repository, name: 'test', raw_data: nil)
      )
    end

    it 'returns error' do
      result = subject.execute(credentials)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq("something went wrong")
    end
  end

  it 'returns error for unknown error causes' do
    message = 'Not Implemented'
    exception = StandardError.new(message)

    allow(client).to receive(:repo).and_raise(exception)

    expect(subject.execute(credentials)).to include({
      status: :error,
      message: "Fogbugz import failed due to an error: #{message}"
    })
  end
end
