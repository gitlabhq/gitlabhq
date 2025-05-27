# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/deprecated_audit_event_service'

RSpec.describe RuboCop::Cop::Gitlab::DeprecatedAuditEventService, feature_category: :tooling do
  let(:msg) do
    'AuditEventService is deprecated and new implementations are not allowed. ' \
      'Instead please use Gitlab::Audit::Auditor. ' \
      'See https://docs.gitlab.com/development/audit_event_guide/#how-to-instrument-new-audit-events'
  end

  it 'flags the use of AuditEventService.new' do
    expect_offense(<<~RUBY)
      AuditEventService.new
      ^^^^^^^^^^^^^^^^^ #{msg}
      ^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'flags the use of AuditEventService with safe navigation operator' do
    expect_offense(<<~RUBY)
      AuditEventService&.new
      ^^^^^^^^^^^^^^^^^ #{msg}
      ^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end
end
