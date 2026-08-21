# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamOutbox, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:entity_type) }
    it { is_expected.to validate_inclusion_of(:entity_type).in_array(described_class::ALLOWED_ENTITY_TYPES) }
    it { is_expected.to validate_presence_of(:entity_id) }
    it { is_expected.to validate_presence_of(:event_type) }

    describe 'payload json schema' do
      it { is_expected.to allow_value({}).for(:payload) }
      it { is_expected.to allow_value({ uid: 'public-client-id' }).for(:payload) }

      context 'when it carries producer-defined keys' do
        it { is_expected.to allow_value({ uid: 'public-client-id', extra: 'producer-defined' }).for(:payload) }
      end

      context 'when it is not an object' do
        it { is_expected.not_to allow_value([1, 2, 3]).for(:payload) }
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:event_type).with_values(upsert: 0, delete: 1) }
  end

  describe 'scopes' do
    describe '.l0_undelivered' do
      let_it_be(:pending) { create(:iam_outbox, l0_delivered_at: nil) }
      let_it_be(:delivered) { create(:iam_outbox, l0_delivered_at: Time.current) }

      it 'returns only rows not yet delivered to L0' do
        expect(described_class.l0_undelivered).to contain_exactly(pending)
      end
    end

    describe '.l2_undelivered' do
      let_it_be(:pending) { create(:iam_outbox, l2_delivered_at: nil) }
      let_it_be(:delivered) { create(:iam_outbox, l2_delivered_at: Time.current) }

      it 'returns only rows not yet delivered to L2' do
        expect(described_class.l2_undelivered).to contain_exactly(pending)
      end
    end

    describe '.l0_undelivered_lookup' do
      let_it_be(:matching) do
        create(:iam_outbox, entity_type: 'oauth_application', entity_id: 42, event_type: :upsert)
      end

      let_it_be(:other_event) do
        create(:iam_outbox, entity_type: 'oauth_application', entity_id: 42, event_type: :delete)
      end

      let_it_be(:other_entity) do
        create(:iam_outbox, entity_type: 'oauth_application', entity_id: 43, event_type: :upsert)
      end

      let_it_be(:already_delivered) do
        create(:iam_outbox, entity_type: 'oauth_application', entity_id: 42, event_type: :upsert,
          l0_delivered_at: Time.current)
      end

      it 'returns only undelivered rows matching the entity type, id, and event type' do
        expect(described_class.l0_undelivered_lookup('oauth_application', 42, :upsert)).to contain_exactly(matching)
      end
    end
  end
end
