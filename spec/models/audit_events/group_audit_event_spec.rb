# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AuditEvents::GroupAuditEvent, feature_category: :audit_events do
  it_behaves_like 'includes ::AuditEvents::CommonModel concern' do
    let_it_be(:audit_event_symbol) { :audit_events_group_audit_event }
    let_it_be(:audit_event_class) { described_class }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group_id) }
  end

  describe 'entity attributes' do
    let_it_be(:event) { create(:audit_events_group_audit_event) }

    it 'maps the scoped column onto the generic entity attributes' do
      expect(event.entity_id).to eq(event.group_id)
      expect(event.entity_type).to eq('Group')
    end
  end

  describe '.by_group' do
    let_it_be(:group_audit_event_1) { create(:audit_events_group_audit_event) }
    let_it_be(:group_audit_event_2) { create(:audit_events_group_audit_event) }

    subject(:event) { described_class.by_group(group_audit_event_1.group_id) }

    it 'returns the correct audit event' do
      expect(event).to contain_exactly(group_audit_event_1)
    end
  end
end
