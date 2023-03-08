# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::UsersImporter, feature_category: :integrations do
  include JiraIntegrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, group: group) }
  let_it_be(:start_at) { 7 }

  let(:importer) { described_class.new(user, project, start_at) }

  subject { importer.execute }

  describe '#execute' do
    let(:mapped_users) do
      [
        {
          jira_account_id: 'acc1',
          jira_display_name: 'user-name1',
          jira_email: 'sample@jira.com',
          gitlab_id: project_member.id
        },
        {
          jira_account_id: 'acc2',
          jira_display_name: 'user-name2',
          jira_email: nil,
          gitlab_id: group_member.id
        }
      ]
    end

    before do
      stub_jira_integration_test
      project.add_maintainer(user)
    end

    context 'when Jira import is not configured properly' do
      it 'returns an error' do
        expect(subject.errors).to eq(['Jira integration not configured.'])
      end
    end

    RSpec.shared_examples 'maps Jira users to GitLab users' do |users_mapper_service:|
      context 'when Jira import is configured correctly' do
        let_it_be(:jira_integration) { create(:jira_integration, project: project, active: true, url: "http://jira.example.net") }

        context 'when users mapper service raises an error' do
          let(:error) { Timeout::Error.new }

          it 'returns an error response' do
            expect_next_instance_of(users_mapper_service) do |instance|
              expect(instance).to receive(:execute).and_raise(error)
            end

            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(error, project_id: project.id)
            expect(subject.error?).to be_truthy
            expect(subject.message).to include('There was an error when communicating to Jira')
          end
        end

        context 'when users mapper service returns result' do
          context 'when users mapper service returns an empty array' do
            it 'returns nil payload' do
              expect_next_instance_of(users_mapper_service) do |instance|
                expect(instance).to receive(:execute).and_return([])
              end

              expect(subject.success?).to be_truthy
              expect(subject.payload).to be_empty
            end
          end

          context 'when Jira client returns any users' do
            let_it_be(:project_member) { create(:user, email: 'sample@jira.com') }
            let_it_be(:group_member) { create(:user, name: 'user-name2') }
            let_it_be(:other_user) { create(:user) }

            before do
              project.add_developer(project_member)
              group.add_developer(group_member)
            end

            it 'returns the mapped users' do
              expect_next_instance_of(users_mapper_service) do |instance|
                expect(instance).to receive(:execute).and_return(mapped_users)
              end

              expect(subject.success?).to be_truthy
              expect(subject.payload).to eq(mapped_users)
            end
          end
        end
      end
    end

    context 'when Jira instance is of Server deployment type' do
      before do
        allow(project).to receive(:jira_integration).and_return(jira_integration)

        jira_integration.data_fields.deployment_server!
      end

      it_behaves_like 'maps Jira users to GitLab users', users_mapper_service: JiraImport::ServerUsersMapperService
    end

    context 'when Jira instance is of Cloud deployment type' do
      before do
        allow(project).to receive(:jira_integration).and_return(jira_integration)

        jira_integration.data_fields.deployment_cloud!
      end

      it_behaves_like 'maps Jira users to GitLab users', users_mapper_service: JiraImport::CloudUsersMapperService
    end
  end
end
