require 'spec_helper'
require 'email_spec'

describe Emails::PagesDomains do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  set(:project) { create(:project) }
  set(:domain) { create(:pages_domain, project: project)  }
  set(:user) { project.owner }

  shared_examples 'a pages domain email' do
    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'has the expected content' do
      aggregate_failures do
        is_expected.to have_subject(email_subject)
        is_expected.to have_body_text(project.human_name)
        is_expected.to have_body_text(domain.domain)
        is_expected.to have_body_text domain.url
        is_expected.to have_body_text project_pages_domain_url(project, domain)
        is_expected.to have_body_text help_page_url('user/project/pages/getting_started_part_three.md', anchor: 'dns-txt-record')
      end
    end
  end

  describe '#pages_domain_enabled_email' do
    let(:email_subject) { "#{project.path} | GitLab Pages domain '#{domain.domain}' has been enabled" }

    subject { Notify.pages_domain_enabled_email(domain, user) }

    it_behaves_like 'a pages domain email'

    it { is_expected.to have_body_text 'has been enabled' }
  end

  describe '#pages_domain_disabled_email' do
    let(:email_subject) { "#{project.path} | GitLab Pages domain '#{domain.domain}' has been disabled" }

    subject { Notify.pages_domain_disabled_email(domain, user) }

    it_behaves_like 'a pages domain email'

    it { is_expected.to have_body_text 'has been disabled' }
  end

  describe '#pages_domain_verification_succeeded_email' do
    let(:email_subject) { "#{project.path} | Verification succeeded for GitLab Pages domain '#{domain.domain}'" }

    subject { Notify.pages_domain_verification_succeeded_email(domain, user) }

    it_behaves_like 'a pages domain email'

    it { is_expected.to have_body_text 'successfully verified' }
  end

  describe '#pages_domain_verification_failed_email' do
    let(:email_subject) { "#{project.path} | ACTION REQUIRED: Verification failed for GitLab Pages domain '#{domain.domain}'" }

    subject { Notify.pages_domain_verification_failed_email(domain, user) }

    it_behaves_like 'a pages domain email'

    it 'says verification has failed and when the domain is enabled until' do
      is_expected.to have_body_text 'Verification has failed'
      is_expected.to have_body_text domain.enabled_until.strftime('%F %T')
    end
  end
end
