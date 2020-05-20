# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::CreateIssueService do
  let(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { User.alert_bot }
  let(:service) { described_class.new(project, alert_payload) }
  let(:alert_starts_at) { Time.current }
  let(:alert_title) { 'TITLE' }
  let(:alert_annotations) { { title: alert_title } }

  let(:alert_payload) do
    build_alert_payload(
      annotations: alert_annotations,
      starts_at: alert_starts_at
    )
  end

  let(:alert_presenter) do
    Gitlab::Alerting::Alert.new(project: project, payload: alert_payload).present
  end

  let!(:setting) do
    create(:project_incident_management_setting, project: project)
  end

  subject { service.execute }

  context 'when create_issue enabled' do
    let(:issue) { subject[:issue] }

    before do
      setting.update!(create_issue: true)
    end

    context 'without issue_template_content' do
      it 'creates an issue with alert summary only' do
        expect(subject).to include(status: :success)

        expect(issue.author).to eq(user)
        expect(issue.title).to eq(alert_title)
        expect(issue.description).to include(alert_presenter.issue_summary_markdown.strip)
        expect(separator_count(issue.description)).to eq(0)
      end
    end

    context 'with erroneous issue service' do
      let(:invalid_issue) do
        build(:issue, project: project, title: nil).tap(&:valid?)
      end

      let(:issue_error) { invalid_issue.errors.full_messages.to_sentence }

      it 'returns and logs the issue error' do
        expect_next_instance_of(Issues::CreateService) do |issue_service|
          expect(issue_service).to receive(:execute).and_return(invalid_issue)
        end

        expect(service)
          .to receive(:log_error)
          .with(error_message(issue_error))

        expect(subject).to include(status: :error, message: issue_error)
      end
    end

    shared_examples 'GFM template' do
      context 'plain content' do
        let(:template_content) { 'some content' }

        it 'creates an issue appending issue template' do
          expect(subject).to include(status: :success)

          expect(issue.description).to include(alert_presenter.issue_summary_markdown)
          expect(separator_count(issue.description)).to eq(1)
          expect(issue.description).to include(template_content)
        end
      end

      context 'quick actions' do
        let(:user) { create(:user) }
        let(:plain_text) { 'some content' }

        let(:template_content) do
          <<~CONTENT
            #{plain_text}
            /due tomorrow
            /assign @#{user.username}
          CONTENT
        end

        before do
          project.add_maintainer(user)
        end

        it 'creates an issue interpreting quick actions' do
          expect(subject).to include(status: :success)

          expect(issue.description).to include(plain_text)
          expect(issue.due_date).to be_present
          expect(issue.assignees).to eq([user])
        end
      end
    end

    context 'with gitlab_incident_markdown' do
      let(:alert_annotations) do
        { title: alert_title, gitlab_incident_markdown: template_content }
      end

      it_behaves_like 'GFM template'
    end

    context 'with issue_template_content' do
      before do
        create_issue_template('bug', template_content)
        setting.update!(issue_template_key: 'bug')
      end

      it_behaves_like 'GFM template'

      context 'and gitlab_incident_markdown' do
        let(:template_content) { 'plain text'}
        let(:alt_template) { 'alternate text' }
        let(:alert_annotations) do
          { title: alert_title, gitlab_incident_markdown: alt_template }
        end

        it 'includes both templates' do
          expect(subject).to include(status: :success)

          expect(issue.description).to include(alert_presenter.issue_summary_markdown)
          expect(issue.description).to include(template_content)
          expect(issue.description).to include(alt_template)
          expect(separator_count(issue.description)).to eq(2)
        end
      end

      private

      def create_issue_template(name, content)
        project.repository.create_file(
          project.creator,
          ".gitlab/issue_templates/#{name}.md",
          content,
          message: 'message',
          branch_name: 'master'
        )
      end
    end

    context 'with gitlab alert' do
      let(:gitlab_alert) { create(:prometheus_alert, project: project) }

      before do
        alert_payload['labels'] = {
          'gitlab_alert_id' => gitlab_alert.prometheus_metric_id.to_s
        }
      end

      it 'creates an issue' do
        query_title = "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold}"

        expect(subject).to include(status: :success)

        expect(issue.author).to eq(user)
        expect(issue.title).to eq(alert_presenter.full_title)
        expect(issue.title).to include(gitlab_alert.environment.name)
        expect(issue.title).to include(query_title)
        expect(issue.title).to include('for 5 minutes')
        expect(issue.description).to include(alert_presenter.issue_summary_markdown.strip)
        expect(separator_count(issue.description)).to eq(0)
      end
    end

    describe 'with invalid alert payload' do
      shared_examples 'invalid alert' do
        it 'does not create an issue' do
          expect(service)
            .to receive(:log_error)
            .with(error_message('invalid alert'))

          expect(subject).to eq(status: :error, message: 'invalid alert')
        end
      end

      context 'without title' do
        let(:alert_annotations) { {} }

        it_behaves_like 'invalid alert'
      end

      context 'without startsAt' do
        let(:alert_starts_at) { nil }

        it_behaves_like 'invalid alert'
      end
    end

    describe "label `incident`" do
      let(:title) { 'incident' }
      let(:color) { '#CC0033' }
      let(:description) do
        <<~DESCRIPTION.chomp
          Denotes a disruption to IT services and \
          the associated issues require immediate attention
        DESCRIPTION
      end

      shared_examples 'existing label' do
        it 'adds the existing label' do
          expect { subject }.not_to change(Label, :count)

          expect(issue.labels).to eq([label])
        end
      end

      shared_examples 'new label' do
        it 'adds newly created label' do
          expect { subject }.to change(Label, :count).by(1)

          label = project.reload.labels.last
          expect(issue.labels).to eq([label])
          expect(label.title).to eq(title)
          expect(label.color).to eq(color)
          expect(label.description).to eq(description)
        end
      end

      context 'with predefined project label' do
        it_behaves_like 'existing label' do
          let!(:label) { create(:label, project: project, title: title) }
        end
      end

      context 'with predefined group label' do
        let(:project) { create(:project, group: group) }
        let(:group) { create(:group) }

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

          expect(service)
            .to receive(:log_info)
            .with(message)

          expect(subject).to include(status: :success)
          expect(issue.labels).to be_empty
        end
      end
    end
  end

  context 'when create_issue disabled' do
    before do
      setting.update!(create_issue: false)
    end

    context 'when skip_settings_check is false (default)' do
      it 'returns an error' do
        expect(service)
          .to receive(:log_error)
          .with(error_message('setting disabled'))

        expect(subject).to eq(status: :error, message: 'setting disabled')
      end
    end

    context 'when skip_settings_check is true' do
      subject { service.execute(skip_settings_check: true) }

      it 'creates an issue' do
        expect { subject }.to change(Issue, :count).by(1)
      end
    end
  end

  private

  def build_alert_payload(annotations: {}, starts_at: Time.current)
    {
      'annotations' => annotations.stringify_keys
    }.tap do |payload|
      payload['startsAt'] = starts_at.rfc3339 if starts_at
    end
  end

  def error_message(message)
    %{Cannot create incident issue for "#{project.full_name}": #{message}}
  end

  def separator_count(text)
    summary_separator = "\n\n---\n\n"

    text.scan(summary_separator).size
  end
end
