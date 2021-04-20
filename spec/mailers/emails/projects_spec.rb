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
        is_expected.not_to have_body_text('Metric:')
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
        is_expected.not_to have_body_text('Metric:')
      end
    end

    context 'with environment' do
      let_it_be(:environment) { create(:environment, project: project) }

      let(:payload) { { 'gitlab_environment_name' => environment.name } }
      let(:metrics_url) { metrics_project_environment_url(project, environment) }

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
        is_expected.not_to have_body_text('Metric:')
      end
    end

    context 'with gitlab alerting rule' do
      let_it_be(:prometheus_alert) { create(:prometheus_alert, project: project) }
      let_it_be(:environment) { prometheus_alert.environment }

      let(:alert) { create(:alert_management_alert, :prometheus, :from_payload, payload: payload, project: project) }
      let(:title) { "#{prometheus_alert.title} #{prometheus_alert.computed_operator} #{prometheus_alert.threshold}" }
      let(:metrics_url) { metrics_project_environment_url(project, environment) }

      before do
        payload['labels'] = {
          'gitlab_alert_id' => prometheus_alert.prometheus_metric_id,
          'alertname' => prometheus_alert.title
        }
      end

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'
      it_behaves_like 'shows the incident issues url'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{environment.name}: #{title} for 5 minutes")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(alert.details_url)
        is_expected.to have_body_text('Environment:')
        is_expected.to have_body_text(environment.name)
        is_expected.to have_body_text('Metric:')
        is_expected.to have_body_text(prometheus_alert.full_query)
        is_expected.to have_body_text(metrics_url)
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
end
