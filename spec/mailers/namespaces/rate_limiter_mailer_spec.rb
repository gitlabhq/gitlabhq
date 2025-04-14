# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::RateLimiterMailer, feature_category: :rate_limiting do
  include EmailSpec::Matchers

  describe '#project_or_group_emails', feature_category: :rate_limiting do
    let(:project) { build_stubbed(:project) }
    let(:recipient) { 'user@example.com' }
    let(:mail) { described_class.project_or_group_emails(project, recipient) }

    subject { mail }

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it_behaves_like 'an email sent from GitLab' do
      let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
      let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
      let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
    end
  end
end
