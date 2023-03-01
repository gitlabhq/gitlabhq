# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::CreateAlertIssueService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:payload) do
    {
      'startsAt' => '2020-04-27T10:10:22.265949279Z',
      'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
    }
  end

  let_it_be(:generic_alert, reload: true) { create(:alert_management_alert, :triggered, project: project, payload: payload) }
  let_it_be(:prometheus_alert, reload: true) { create(:alert_management_alert, :triggered, :prometheus, project: project, payload: payload) }

  let(:alert) { generic_alert }
  let(:alert_presenter) { alert.present }
  let(:created_issue) { Issue.last! }

  describe '#execute' do
    subject(:execute) { described_class.new(alert, user).execute }

    before do
      allow(user).to receive(:can?).and_call_original
      allow(user).to receive(:can?)
        .with(:create_issue, project)
        .and_return(can_create)
    end

    shared_examples 'creating an alert issue' do
      it 'creates an issue' do
        expect { execute }.to change { project.issues.count }.by(1)
      end

      it 'returns a created issue' do
        expect(execute.payload).to eq(issue: created_issue)
      end

      it 'has a successful status' do
        expect(execute).to be_success
      end

      it 'sets alert.issue_id in the same ActiveRecord query execution' do
        execute

        expect(alert.issue_id).to eq(created_issue.id)
      end

      it 'creates a system note' do
        expect { execute }.to change { alert.reload.notes.count }.by(1)
      end
    end

    shared_examples 'setting an issue attributes' do
      before do
        execute
      end

      it 'sets issue author to the current user' do
        expect(created_issue.author).to eq(user)
      end

      it 'sets the issue title' do
        expect(created_issue.title).to eq(alert.title)
      end

      it 'sets the issue description' do
        expect(created_issue.description).to include(alert_presenter.send(:issue_summary_markdown).strip)
      end
    end

    context 'when a user is allowed to create an issue' do
      let(:can_create) { true }

      before do
        project.add_developer(user)
      end

      it 'checks permissions' do
        execute
        expect(user).to have_received(:can?).with(:create_issue, project).exactly(2).times
      end

      context 'with alert severity' do
        using RSpec::Parameterized::TableSyntax

        where(:alert_severity, :incident_severity) do
          'critical' | 'critical'
          'high'     | 'high'
          'medium'   | 'medium'
          'low'      | 'low'
          'info'     | 'unknown'
          'unknown'  | 'unknown'
        end

        with_them do
          before do
            alert.update!(severity: alert_severity)
            execute
          end

          it 'sets the correct severity level' do
            expect(created_issue.severity).to eq(incident_severity)
          end
        end
      end

      context 'when the alert is prometheus alert' do
        let(:alert) { prometheus_alert }
        let(:issue) { subject.payload[:issue] }

        it_behaves_like 'creating an alert issue'
        it_behaves_like 'setting an issue attributes'
      end

      context 'when the alert is generic' do
        let(:alert) { generic_alert }
        let(:issue) { subject.payload[:issue] }
        let(:default_alert_title) { described_class::DEFAULT_ALERT_TITLE }

        it_behaves_like 'creating an alert issue'
        it_behaves_like 'setting an issue attributes'

        context 'when alert title matches the default title exactly' do
          before do
            generic_alert.update!(title: default_alert_title)
          end

          it 'updates issue title with the IID' do
            execute

            expect(created_issue.title).to eq("New: Incident #{created_issue.iid}")
          end
        end

        context 'when the alert title contains the default title' do
          let(:non_default_alert_title) { "Not #{default_alert_title}" }

          before do
            generic_alert.update!(title: non_default_alert_title)
          end

          it 'does not change issue title' do
            execute

            expect(created_issue.title).to eq(non_default_alert_title)
          end
        end
      end

      context 'when issue cannot be created' do
        let(:alert) { generic_alert }

        before do
          # Invalid alert
          alert.update_columns(title: '')
        end

        it 'has an unsuccessful status' do
          expect(execute).to be_error
          expect(execute.errors).to contain_exactly("Title can't be blank")
        end
      end

      context 'when alert cannot be updated' do
        let(:alert) { create(:alert_management_alert, :with_validation_errors, :triggered, project: project, payload: payload) }

        it 'responds with error' do
          expect(execute).to be_error
          expect(execute.errors).to contain_exactly('Hosts hosts array is over 255 chars')
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
