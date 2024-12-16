# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DatabasesController, :snowplow, feature_category: :deployment_management do
  shared_examples 'shared examples for database controller endpoints' do
    include_examples 'requires `admin_project_google_cloud` role'

    include_examples 'requires valid Google OAuth2 configuration'

    include_examples 'requires valid Google Oauth2 token' do
      let_it_be(:mock_gcp_projects) { [{}, {}, {}] }
      let_it_be(:mock_branches) { [] }
      let_it_be(:mock_tags) { [] }
    end
  end

  context '-/google_cloud/databases' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/index' }
    let_it_be(:redirects_to) { nil }

    subject { get project_google_cloud_databases_path(project) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/postgres' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :postgres) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/mysql' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :mysql) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/sqlserver' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :sqlserver) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/create' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { nil }
    let_it_be(:redirects_to) { project_google_cloud_databases_path(project) }

    subject { post project_google_cloud_databases_path(project) }

    include_examples 'shared examples for database controller endpoints'

    context 'when the request is valid' do
      before do
        project.add_maintainer(user)
        sign_in(user)

        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          allow(client).to receive(:validate_token).and_return(true)
          allow(client).to receive(:list_projects).and_return(mock_gcp_projects)
        end

        allow_next_instance_of(BranchesFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches)
        end

        allow_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches)
        end
      end

      subject do
        post project_google_cloud_databases_path(project)
      end

      context 'when EnableCloudsqlService fails' do
        before do
          allow_next_instance_of(::CloudSeed::GoogleCloud::EnableCloudsqlService) do |service|
            allow(service).to receive(:execute)
                                 .and_return({ status: :error, message: 'error' })
          end
        end

        it 'redirects and track event on error' do
          subject

          expect(response).to redirect_to(project_google_cloud_databases_path(project))

          expect_snowplow_event(
            category: 'Projects::GoogleCloud::DatabasesController',
            action: 'error_enable_cloudsql_services',
            label: nil,
            project: project,
            user: user
          )
        end

        it 'shows a flash alert' do
          subject

          expect(flash[:alert]).to eq(s_('CloudSeed|Google Cloud Error - error'))
        end
      end

      context 'when EnableCloudsqlService is successful' do
        before do
          allow_next_instance_of(::CloudSeed::GoogleCloud::EnableCloudsqlService) do |service|
            allow(service).to receive(:execute)
                                .and_return({ status: :success, message: 'success' })
          end
        end

        context 'when CreateCloudsqlInstanceService fails' do
          before do
            allow_next_instance_of(::CloudSeed::GoogleCloud::CreateCloudsqlInstanceService) do |service|
              allow(service).to receive(:execute)
                                   .and_return({ status: :error, message: 'error' })
            end
          end

          it 'redirects and track event on error' do
            subject

            expect(response).to redirect_to(project_google_cloud_databases_path(project))

            expect_snowplow_event(
              category: 'Projects::GoogleCloud::DatabasesController',
              action: 'error_create_cloudsql_instance',
              label: nil,
              project: project,
              user: user
            )
          end

          it 'shows a flash warning' do
            subject

            expect(flash[:warning]).to eq(s_('CloudSeed|Google Cloud Error - error'))
          end
        end

        context 'when CreateCloudsqlInstanceService is successful' do
          before do
            allow_next_instance_of(::CloudSeed::GoogleCloud::CreateCloudsqlInstanceService) do |service|
              allow(service).to receive(:execute)
                                  .and_return({ status: :success, message: 'success' })
            end
          end

          it 'redirects as expected' do
            subject

            expect(response).to redirect_to(project_google_cloud_databases_path(project))

            expect_snowplow_event(
              category: 'Projects::GoogleCloud::DatabasesController',
              action: 'create_cloudsql_instance',
              label: "{}",
              project: project,
              user: user
            )
          end

          it 'shows a flash notice' do
            subject

            expect(flash[:notice])
              .to eq(
                s_(
                  'CloudSeed|Cloud SQL instance creation request successful. ' \
                  'Expected resolution time is ~5 minutes.'
                )
              )
          end
        end
      end
    end
  end
end
