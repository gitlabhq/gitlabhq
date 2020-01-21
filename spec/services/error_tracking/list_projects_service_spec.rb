# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ListProjectsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:new_api_host) { 'https://gitlab.com/' }
  let(:new_token) { 'new-token' }
  let(:params) { ActionController::Parameters.new(api_host: new_api_host, token: new_token) }

  let(:error_tracking_setting) do
    create(:project_error_tracking_setting, api_url: sentry_url, token: token, project: project)
  end

  subject { described_class.new(project, user, params) }

  before do
    project.add_reporter(user)
  end

  describe '#execute' do
    let(:result) { subject.execute }

    context 'with authorized user' do
      before do
        expect(project).to receive(:error_tracking_setting).at_least(:once)
          .and_return(error_tracking_setting)
      end

      context 'set model attributes to new values' do
        let(:new_api_url) { new_api_host + 'api/0/projects/org/proj/' }

        before do
          expect(error_tracking_setting).to receive(:list_sentry_projects)
            .and_return({ projects: [] })
        end

        it 'uses new api_url and token' do
          subject.execute

          expect(error_tracking_setting.api_url).to eq(new_api_url)
          expect(error_tracking_setting.token).to eq(new_token)
          error_tracking_setting.reload
          expect(error_tracking_setting.api_url).to eq(sentry_url)
          expect(error_tracking_setting.token).to eq(token)
        end
      end

      context 'masked param token' do
        let(:params) { ActionController::Parameters.new(token: "*********", api_host: new_api_host) }

        before do
          expect(error_tracking_setting).to receive(:list_sentry_projects)
            .and_return({ projects: [] })
        end

        it 'uses database token' do
          expect { subject.execute }.not_to change { error_tracking_setting.token }
        end
      end

      context 'sentry client raises exception' do
        context 'Sentry::Client::Error' do
          before do
            expect(error_tracking_setting).to receive(:list_sentry_projects)
              .and_raise(Sentry::Client::Error, 'Sentry response status code: 500')
          end

          it 'returns error response' do
            expect(result[:message]).to eq('Sentry response status code: 500')
            expect(result[:http_status]).to eq(:bad_request)
          end
        end

        context 'Sentry::Client::MissingKeysError' do
          before do
            expect(error_tracking_setting).to receive(:list_sentry_projects)
              .and_raise(Sentry::Client::MissingKeysError, 'Sentry API response is missing keys. key not found: "id"')
          end

          it 'returns error response' do
            expect(result[:message]).to eq('Sentry API response is missing keys. key not found: "id"')
            expect(result[:http_status]).to eq(:internal_server_error)
          end
        end
      end

      context 'with invalid url' do
        let(:params) do
          ActionController::Parameters.new(
            api_host: 'https://localhost',
            token: new_token
          )
        end

        before do
          error_tracking_setting.enabled = false
        end

        it 'returns error' do
          expect(result[:message]).to start_with('Api url is blocked')
          expect(error_tracking_setting).not_to be_valid
        end
      end

      context 'when list_sentry_projects returns projects' do
        let(:projects) { [:list, :of, :projects] }

        before do
          expect(error_tracking_setting)
            .to receive(:list_sentry_projects).and_return(projects: projects)
        end

        it 'returns the projects' do
          expect(result).to eq(status: :success, projects: projects)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        project.add_guest(user)
      end

      it 'returns error' do
        expect(result).to include(status: :error, message: 'Access denied', http_status: :unauthorized)
      end
    end

    context 'with error tracking disabled' do
      before do
        expect(project).to receive(:error_tracking_setting).at_least(:once)
          .and_return(error_tracking_setting)
        expect(error_tracking_setting)
          .to receive(:list_sentry_projects).and_return(projects: [])

        error_tracking_setting.enabled = false
      end

      it 'ignores enabled flag' do
        expect(result).to include(status: :success, projects: [])
      end
    end

    context 'error_tracking_setting is nil' do
      let(:error_tracking_setting) { build(:project_error_tracking_setting) }
      let(:new_api_url) { new_api_host + 'api/0/projects/org/proj/' }

      before do
        expect(project).to receive(:build_error_tracking_setting).once
          .and_return(error_tracking_setting)

        expect(error_tracking_setting).to receive(:list_sentry_projects)
          .and_return(projects: [:project1, :project2])
      end

      it 'builds a new error_tracking_setting' do
        expect(project.error_tracking_setting).to be_nil

        expect(result[:projects]).to eq([:project1, :project2])

        expect(error_tracking_setting.api_url).to eq(new_api_url)
        expect(error_tracking_setting.token).to eq(new_token)
        expect(error_tracking_setting.enabled).to be true
        expect(error_tracking_setting.persisted?).to be false
        expect(error_tracking_setting.project_id).not_to be_nil

        expect(project.error_tracking_setting).to be_nil
      end
    end
  end
end
