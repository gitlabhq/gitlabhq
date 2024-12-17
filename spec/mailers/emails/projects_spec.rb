# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Projects do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  shared_examples 'no email' do
    it 'does not send mail' do
      expect(subject.message).to be_a_kind_of(ActionMailer::Base::NullMail)
    end
  end

  shared_examples 'shows the incident issues url' do
    context 'create issue setting enabled' do
      before do
        create(:project_incident_management_setting, project: project, create_issue: true)
      end

      let(:incidents_url) { project_incidents_url(project) }

      it { is_expected.to have_body_text(incidents_url) }
    end
  end

  let_it_be(:user) { create(:user) }

  describe '#prometheus_alert_fired_email' do
    let(:default_title) { Gitlab::AlertManagement::Payload::Generic::DEFAULT_TITLE }
    let(:payload) { { 'startsAt' => Time.now.rfc3339 } }
    let(:alert) { create(:alert_management_alert, :from_payload, payload: payload, project: project) }

    subject do
      Notify.prometheus_alert_fired_email(project, user, alert)
    end

    it_behaves_like 'an email with X-GitLab headers containing project details'

    it 'has expected X-GitLab alert headers', :aggregate_failures do
      is_expected.to have_header('X-GitLab-Alert-ID', /#{alert.id}/)
      is_expected.to have_header('X-GitLab-Alert-IID', /#{alert.iid}/)
      is_expected.to have_header('X-GitLab-NotificationReason', "alert_#{alert.state}")

      is_expected.not_to have_header('X-GitLab-Incident-ID', /.+/)
      is_expected.not_to have_header('X-GitLab-Incident-IID', /.+/)
    end

    context 'with incident' do
      let(:alert) { create(:alert_management_alert, :with_incident, :from_payload, payload: payload, project: project) }
      let(:incident) { alert.issue }

      it 'has expected X-GitLab incident headers', :aggregate_failures do
        is_expected.to have_header('X-GitLab-Incident-ID', /#{incident.id}/)
        is_expected.to have_header('X-GitLab-Incident-IID', /#{incident.iid}/)
      end
    end

    context 'with empty payload' do
      let(:payload) { {} }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{default_title}")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(alert.details_url)
        is_expected.not_to have_body_text('Description:')
        is_expected.not_to have_body_text('Environment:')
      end
    end

    context 'with description' do
      let(:payload) { { 'description' => 'alert description' } }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{default_title}")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(alert.details_url)
        is_expected.to have_body_text('Description:')
        is_expected.to have_body_text('alert description')
        is_expected.not_to have_body_text('Environment:')
      end
    end

    context 'with environment' do
      let_it_be(:environment) { create(:environment, project: project) }

      let(:payload) { { 'gitlab_environment_name' => environment.name } }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{environment.name}: #{default_title}")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(alert.details_url)
        is_expected.to have_body_text('Environment:')
        is_expected.to have_body_text(environment.name)
        is_expected.not_to have_body_text('Description:')
      end
    end

    context 'resolved' do
      let_it_be(:alert) { create(:alert_management_alert, :resolved, project: project) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{alert.title}")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been resolved')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(alert.details_url)
      end
    end
  end

  describe '#repository_rewrite_history_success_email' do
    let(:recipient) { user }

    subject { Notify.repository_rewrite_history_success_email(project, user) }

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Project history rewrite has completed")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text("Repository history rewrite succeeded on")
    end
  end

  describe '#repository_rewrite_history_failure_email' do
    let(:recipient) { user }
    let(:error) { 'Some error' }

    subject { Notify.repository_rewrite_history_failure_email(project, user, error) }

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Project history rewrite failure")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text("Repository history rewrite failed on")
      is_expected.to have_body_text(error)
    end
  end

  describe '#repository_push_email' do
    let(:recipient) { user }

    subject { Notify.repository_push_email(project.id, { author_id: user.id, ref: 'main', action: :create }) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
    it_behaves_like 'an email with suffix'

    it 'has the correct subject and body' do
      is_expected.to have_subject("[Git][#{project.full_path}] Pushed new branch main")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text("#{user.name} pushed new branch main at")
    end
  end

  describe '.inactive_project_deletion_warning_email' do
    let(:recipient) { user }
    let(:deletion_date) { "2022-01-10" }

    subject { Notify.inactive_project_deletion_warning_email(project, user, deletion_date) }

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      project_link = "<a href=\"#{project.http_url_to_repo}\">#{project.name}</a>"

      is_expected.to have_subject("#{project.name} | Action required: Project #{project.name} is scheduled to be " \
        "deleted on 2022-01-10 due to inactivity")
      is_expected.to have_body_text(project.http_url_to_repo)
      is_expected.to have_body_text("Due to inactivity, the #{project_link} project is scheduled to be deleted " \
        "on <b>2022-01-10</b>")
      is_expected.to have_body_text("To ensure #{project_link} is unscheduled for deletion, check that activity has " \
        "been logged by GitLab")
      is_expected.to have_body_text("This email supersedes any previous emails about scheduled deletion you may " \
        "have received for #{project_link}.")
    end
  end

  describe '.project_was_exported_email' do
    let(:recipient) { user }

    subject { Notify.project_was_exported_email(user, project) }

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Project was exported")
      is_expected.to have_body_text("Project #{project.name} was exported successfully.")
      is_expected.to have_body_text("The download link will expire in 24 hours.")
    end
  end

  describe '.project_was_moved_email' do
    let(:recipient) { user }
    let(:old_path_with_namespace) { project.path_with_namespace }

    subject { Notify.project_was_moved_email(project.id, user.id, old_path_with_namespace) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Project was moved")
      is_expected.to have_body_text("Project #{project.path_with_namespace} was moved to another location.")
      is_expected.to have_body_text("To update the remote url in your local repository run (for ssh):")
    end
  end

  describe '.project_was_not_exported_email' do
    let(:recipient) { user }

    errors =  ['Some error']

    subject { Notify.project_was_not_exported_email(user, project, errors) }

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Project export error")
      is_expected.to have_body_text("#{project.name} | Project export error")
    end
  end
end
