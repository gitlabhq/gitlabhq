# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::CreateAlertIssueService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:payload) do
    {
      'annotations' => {
        'title' => 'Alert title'
      },
      'startsAt' => '2020-04-27T10:10:22.265949279Z',
      'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
    }
  end
  let_it_be(:generic_alert, reload: true) { create(:alert_management_alert, :triggered, project: project, payload: payload) }
  let_it_be(:prometheus_alert) { create(:alert_management_alert, :triggered, :prometheus, project: project, payload: payload) }
  let(:alert) { generic_alert }
  let(:created_issue) { Issue.last! }

  describe '#execute' do
    subject(:execute) { described_class.new(alert, user).execute }

    before do
      allow(user).to receive(:can?).and_call_original
      allow(user).to receive(:can?)
        .with(:create_issue, project)
        .and_return(can_create)
    end

    shared_examples 'creating an alert' do
      it 'creates an issue' do
        expect { execute }.to change { project.issues.count }.by(1)
      end

      it 'returns a created issue' do
        expect(execute.payload).to eq(issue: created_issue)
      end

      it 'has a successful status' do
        expect(execute).to be_success
      end

      it 'updates alert.issue_id' do
        execute

        expect(alert.reload.issue_id).to eq(created_issue.id)
      end

      it 'sets issue author to the current user' do
        execute

        expect(created_issue.author).to eq(user)
      end
    end

    context 'when a user is allowed to create an issue' do
      let(:can_create) { true }

      before do
        project.add_developer(user)
      end

      it 'checks permissions' do
        execute
        expect(user).to have_received(:can?).with(:create_issue, project)
      end

      context 'when the alert is prometheus alert' do
        let(:alert) { prometheus_alert }

        it_behaves_like 'creating an alert'
      end

      context 'when the alert is generic' do
        let(:alert) { generic_alert }

        it_behaves_like 'creating an alert'
      end

      context 'when issue cannot be created' do
        let(:alert) { prometheus_alert }

        before do
          # set invalid payload for Prometheus alert
          alert.update!(payload: {})
        end

        it 'has an unsuccessful status' do
          expect(execute).to be_error
          expect(execute.message).to eq('invalid alert')
        end
      end

      context 'when alert cannot be updated' do
        let(:alert) { create(:alert_management_alert, :with_validation_errors, :triggered, project: project, payload: payload) }

        it 'responds with error' do
          expect(execute).to be_error
          expect(execute.message).to eq('Hosts hosts array is over 255 chars')
        end
      end

      context 'when alert already has an attached issue' do
        let!(:issue) { create(:issue, project: project) }

        before do
          alert.update!(issue_id: issue.id)
        end

        it 'does not create yet another issue' do
          expect { execute }.not_to change(Issue, :count)
        end

        it 'responds with error' do
          expect(execute).to be_error
          expect(execute.message).to eq(_('An issue already exists'))
        end
      end
    end

    context 'when a user is not allowed to create an issue' do
      let(:can_create) { false }

      it 'checks permissions' do
        execute
        expect(user).to have_received(:can?).with(:create_issue, project)
      end

      it 'responds with error' do
        expect(execute).to be_error
        expect(execute.message).to eq(_('You have no permissions'))
      end
    end
  end
end
