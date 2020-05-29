# frozen_string_literal: true

require 'spec_helper'

describe JiraImport::UsersImporter do
  include JiraServiceHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:start_at) { 7 }

  let(:importer) { described_class.new(user, project, start_at) }

  subject { importer.execute }

  describe '#execute' do
    before do
      stub_jira_service_test
      project.add_maintainer(user)
    end

    context 'when Jira import is not configured properly' do
      it 'raises an error' do
        expect { subject }.to raise_error(Projects::ImportService::Error)
      end
    end

    context 'when Jira import is configured correctly' do
      let_it_be(:jira_service) { create(:jira_service, project: project, active: true) }
      let(:client) { double }

      before do
        expect(importer).to receive(:client).and_return(client)
      end

      context 'when jira client raises an error' do
        it 'returns an error response' do
          expect(client).to receive(:get).and_raise(Timeout::Error)

          expect(subject.error?).to be_truthy
          expect(subject.message).to include('There was an error when communicating to Jira')
        end
      end

      context 'when jira client returns result' do
        before do
          allow(client).to receive(:get).with('/rest/api/2/users?maxResults=50&startAt=7')
            .and_return(jira_users)
        end

        context 'when jira client returns an empty array' do
          let(:jira_users) { [] }

          it 'retturns nil payload' do
            expect(subject.success?).to be_truthy
            expect(subject.payload).to be_nil
          end
        end

        context 'when jira client returns an results' do
          let(:jira_users)   { [{ 'name' => 'user1' }, { 'name' => 'user2' }] }
          let(:mapped_users) { [{ jira_display_name: 'user1', gitlab_id: 5 }] }

          before do
            expect(JiraImport::UsersMapper).to receive(:new).with(project, jira_users)
            .and_return(double(execute: mapped_users))
          end

          it 'returns the mapped users' do
            expect(subject.success?).to be_truthy
            expect(subject.payload).to eq(mapped_users)
          end
        end
      end
    end
  end
end
