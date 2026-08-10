# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AuditEvents::UserAuditEvent, feature_category: :audit_events do
  it_behaves_like 'includes ::AuditEvents::CommonModel concern' do
    let_it_be(:audit_event_symbol) { :audit_events_user_audit_event }
    let_it_be(:audit_event_class) { described_class }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'entity attributes' do
    let_it_be(:target_user) { create(:user) }

    # Built directly rather than from the factory: the factory assigns `user`, which is
    # the author association, and EE resolves the entity from that ivar instead of user_id.
    let(:event) { described_class.new(user_id: target_user.id) }

    it 'maps the scoped column onto the generic entity attributes' do
      expect(event.entity_id).to eq(target_user.id)
      expect(event.entity_type).to eq('User')
    end
  end

  describe '.by_user' do
    let_it_be(:user_audit_event_1) { create(:audit_events_user_audit_event) }
    let_it_be(:user_audit_event_2) { create(:audit_events_user_audit_event) }

    subject(:event) { described_class.by_user(user_audit_event_1.user_id) }

    it 'returns the correct audit event' do
      expect(event).to contain_exactly(user_audit_event_1)
    end
  end

  describe '.by_username' do
    let_it_be(:user_audit_event_1) { create(:audit_events_user_audit_event) }
    let_it_be(:user_audit_event_2) { create(:audit_events_user_audit_event) }

    subject(:event) { described_class.by_username(user_audit_event_1.user.username) }

    before do
      fake_user = build_stubbed(:user, id: user_audit_event_1.user_id)

      allow(User).to receive(:find_by_username)
                    .with(user_audit_event_1.user.username)
                    .and_return(fake_user)
    end

    it 'returns the correct audit event' do
      expect(event).to contain_exactly(user_audit_event_1)
    end
  end
end
