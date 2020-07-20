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

      let(:incident_issues_url) do
        project_issues_url(project, label_name: 'incident')
      end

      it { is_expected.to have_body_text(incident_issues_url) }
    end
  end

  let_it_be(:user) { create(:user) }

  describe '#prometheus_alert_fired_email' do
    subject do
      Notify.prometheus_alert_fired_email(project.id, user.id, alert_params)
    end

    let(:alert_params) do
      { 'startsAt' => Time.now.rfc3339 }
    end

    context 'with a gitlab alert' do
      before do
        alert_params['labels'] = { 'gitlab_alert_id' => alert.prometheus_metric_id.to_s }
      end

      let(:title) do
        "#{alert.title} #{alert.computed_operator} #{alert.threshold}"
      end

      let(:metrics_url) do
        metrics_project_environment_url(project, environment)
      end

      let(:environment) { alert.environment }

      let!(:alert) { create(:prometheus_alert, project: project) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{environment.name}: #{title} for 5 minutes")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text('Environment:')
        is_expected.to have_body_text(environment.name)
        is_expected.to have_body_text('Metric:')
        is_expected.to have_body_text(alert.full_query)
        is_expected.to have_body_text(metrics_url)
      end

      it_behaves_like 'shows the incident issues url'
    end

    context 'with no payload' do
      let(:alert_params) { {} }

      it_behaves_like 'no email'
    end

    context 'with an unknown alert' do
      before do
        alert_params['labels'] = { 'gitlab_alert_id' => 'unknown' }
      end

      it_behaves_like 'no email'
    end

    context 'with an external alert' do
      let(:title) { 'alert title' }

      let(:metrics_url) do
        metrics_project_environments_url(project)
      end

      before do
        alert_params['annotations'] = { 'title' => title }
        alert_params['generatorURL'] = 'http://localhost:9090/graph?g0.expr=vector%281%29&g0.tab=1'
      end

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        is_expected.to have_subject("#{project.name} | Alert: #{title}")
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.not_to have_body_text('Description:')
        is_expected.not_to have_body_text('Environment:')
      end

      context 'with annotated description' do
        let(:description) { 'description' }

        before do
          alert_params['annotations']['description'] = description
        end

        it 'shows the description' do
          is_expected.to have_body_text('Description:')
          is_expected.to have_body_text(description)
        end
      end

      it_behaves_like 'shows the incident issues url'
    end
  end
end
