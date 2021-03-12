# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::UsersImporter do
  include JiraServiceHelper

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
      stub_jira_service_test
      project.add_maintainer(user)
    end

    context 'when Jira import is not configured properly' do
      it 'returns an error' do
        expect(subject.errors).to eq(['Jira integration not configured.'])
      end
    end

    RSpec.shared_examples 'maps jira users to gitlab users' do
      context 'when Jira import is configured correctly' do
        let_it_be(:jira_service) { create(:jira_service, project: project, active: true) }
        let(:client) { double }

        before do
          expect(importer).to receive(:client).at_least(1).and_return(client)
          allow(client).to receive_message_chain(:ServerInfo, :all, :deploymentType).and_return(deployment_type)
        end

        context 'when jira client raises an error' do
          let(:error) { Timeout::Error.new }

          it 'returns an error response' do
            expect(client).to receive(:get).and_raise(error)
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(error, project_id: project.id)

            expect(subject.error?).to be_truthy
            expect(subject.message).to include('There was an error when communicating to Jira')
          end
        end

        context 'when jira client returns result' do
          context 'when jira client returns an empty array' do
            let(:jira_users) { [] }

            it 'returns nil payload' do
              expect(subject.success?).to be_truthy
              expect(subject.payload).to be_empty
            end
          end

          context 'when jira client returns an results' do
            let_it_be(:project_member) { create(:user, email: 'sample@jira.com') }
            let_it_be(:group_member) { create(:user, name: 'user-name2') }
            let_it_be(:other_user) { create(:user) }

            before do
              project.add_developer(project_member)
              group.add_developer(group_member)
            end

            it 'returns the mapped users' do
              expect(subject.success?).to be_truthy
              expect(subject.payload).to eq(mapped_users)
            end
          end
        end
      end
    end

    context 'when Jira instance is of Server deployment type' do
      let(:deployment_type) { 'Server' }
      let(:url) { "/rest/api/2/user/search?username=''&maxResults=50&startAt=#{start_at}" }
      let(:jira_users) do
        [
          { 'key' => 'acc1', 'name' => 'user-name1', 'emailAddress' => 'sample@jira.com' },
          { 'key' => 'acc2', 'name' => 'user-name2' }
        ]
      end

      before do
        allow_next_instance_of(JiraImport::ServerUsersMapperService) do |instance|
          allow(instance).to receive(:client).and_return(client)
          allow(client).to receive(:get).with(url).and_return(jira_users)
        end
      end

      it_behaves_like 'maps jira users to gitlab users'
    end

    context 'when Jira instance is of Cloud deploymet type' do
      let(:deployment_type) { 'Cloud' }
      let(:url) { "/rest/api/2/users?maxResults=50&startAt=#{start_at}" }
      let(:jira_users) do
        [
          { 'accountId' => 'acc1', 'displayName' => 'user-name1', 'emailAddress' => 'sample@jira.com' },
          { 'accountId' => 'acc2', 'displayName' => 'user-name2' }
        ]
      end

      before do
        allow_next_instance_of(JiraImport::CloudUsersMapperService) do |instance|
          allow(instance).to receive(:client).and_return(client)
          allow(client).to receive(:get).with(url).and_return(jira_users)
        end
      end

      it_behaves_like 'maps jira users to gitlab users'
    end
  end
end
