# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AuditEvents::InstanceAuditEvent, feature_category: :audit_events do
  it_behaves_like 'includes ::AuditEvents::CommonModel concern' do
    let_it_be(:audit_event_symbol) { :audit_events_instance_audit_event }
    let_it_be(:audit_event_class) { described_class }
  end

  describe 'entity attributes' do
    let_it_be(:event) { create(:audit_events_instance_audit_event) }

    it 'has no entity id and reports the instance scope as its type' do
      expect(event.entity_id).to be_nil
      expect(event.entity_type).to eq('Gitlab::Audit::InstanceScope')
    end
  end
end
