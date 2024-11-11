# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AuditEvents::ProjectAuditEvent, feature_category: :audit_events do
  it_behaves_like 'includes ::AuditEvents::CommonModel concern' do
    let_it_be(:audit_event_symbol) { :audit_events_project_audit_event }
    let_it_be(:audit_event_class) { described_class }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '.by_project' do
    let_it_be(:project_audit_event_1) { create(:audit_events_project_audit_event) }
    let_it_be(:project_audit_event_2) { create(:audit_events_project_audit_event) }

    subject(:event) { described_class.by_project(project_audit_event_1.project_id) }

    it 'returns the correct audit event' do
      expect(event).to contain_exactly(project_audit_event_1)
    end
  end
end
