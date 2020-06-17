# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::CreateAlertIssueService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:payload) do
    {
      'title' => 'Alert title',
      'annotations' => {
        'title' => 'Alert title'
      },
      'startsAt' => '2020-04-27T10:10:22.265949279Z',
      'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
    }
  end
  let_it_be(:generic_alert, reload: true) { create(:alert_management_alert, :triggered, project: project, payload: payload) }
  let_it_be(:prometheus_alert, reload: true) { create(:alert_management_alert, :triggered, :prometheus, project: project, payload: payload) }
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

      it 'updates alert.issue_id' do
        execute

        expect(alert.reload.issue_id).to eq(created_issue.id)
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
        expect(created_issue.title).to eq(alert_presenter.title)
      end

      it 'sets the issue description' do
        expect(created_issue.description).to include(alert_presenter.issue_summary_markdown.strip)
      end
    end

    shared_examples 'sets issue labels' do
      let(:title) { 'incident' }
      let(:color) { '#CC0033' }
      let(:description) do
        <<~DESCRIPTION.chomp
          Denotes a disruption to IT services and \
          the associated issues require immediate attention
        DESCRIPTION
      end

      shared_examples 'existing label' do
        it 'does not create new label' do
          expect { execute }.not_to change(Label, :count)
        end

        it 'adds the existing label' do
          execute

          expect(created_issue.labels).to eq([label])
        end
      end

      shared_examples 'new label' do
        it 'adds newly created label' do
          expect { execute }.to change(Label, :count).by(1)
        end

        it 'sets label attributes' do
          execute

          created_label = project.reload.labels.last!
          expect(created_issue.labels).to eq([created_label])
          expect(created_label.title).to eq(title)
          expect(created_label.color).to eq(color)
          expect(created_label.description).to eq(description)
        end
      end

      context 'with predefined project label' do
        it_behaves_like 'existing label' do
          let!(:label) { create(:label, project: project, title: title) }
        end
      end

      context 'with predefined group label' do
        it_behaves_like 'existing label' do
          let!(:label) { create(:group_label, group: group, title: title) }
        end
      end

      context 'without label' do
        it_behaves_like 'new label'
      end

      context 'with duplicate labels', issue: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/65042' do
        before do
          # Replicate race condition to create duplicates
          build(:label, project: project, title: title).save!(validate: false)
          build(:label, project: project, title: title).save!(validate: false)
        end

        it 'create an issue without labels' do
          # Verify we have duplicates
          expect(project.labels.size).to eq(2)
          expect(project.labels.map(&:title)).to all(eq(title))

          message = <<~MESSAGE.chomp
            Cannot create incident issue with labels ["#{title}"] for \
            "#{project.full_name}": Labels is invalid.
            Retrying without labels.
          MESSAGE

          expect(Gitlab::AppLogger)
            .to receive(:info)
            .with(message)

          expect(execute).to be_success
          expect(created_issue.labels).to be_empty
        end
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
        let(:alert_presenter) do
          Gitlab::Alerting::Alert.new(project: project, payload: alert.payload).present
        end

        it_behaves_like 'creating an alert issue'
        it_behaves_like 'setting an issue attributes'
        it_behaves_like 'sets issue labels'
      end

      context 'when the alert is generic' do
        let(:alert) { generic_alert }
        let(:alert_presenter) do
          alert_payload = Gitlab::Alerting::NotificationPayloadParser.call(alert.payload.to_h)
          Gitlab::Alerting::Alert.new(project: project, payload: alert_payload).present
        end

        it_behaves_like 'creating an alert issue'
        it_behaves_like 'setting an issue attributes'
        it_behaves_like 'sets issue labels'
      end

      context 'when issue cannot be created' do
        let(:alert) { prometheus_alert }

        before do
          # set invalid payload for Prometheus alert
          alert.update!(payload: {})
        end

        it 'has an unsuccessful status' do
          expect(execute).to be_error
          expect(execute.message).to eq("Title can't be blank")
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
