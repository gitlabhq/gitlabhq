# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AuditEvents::InstanceAuditEvent, feature_category: :audit_events do
  it_behaves_like 'includes ::AuditEvents::CommonModel concern' do
    let_it_be(:audit_event_symbol, freeze: false) { :audit_events_instance_audit_event }
    let_it_be(:audit_event_class, freeze: false) { described_class }
  end
end
