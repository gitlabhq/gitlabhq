# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::CreateService, feature_category: :source_code_management do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:params) { attributes_for(:key, user: user).except(:organization) }

  subject { described_class.new(user, params) }

  context 'notification', :mailer do
    it 'sends a notification' do
      perform_enqueued_jobs do
        subject.execute
      end
      should_email(user)
    end
  end

  it 'creates a key' do
    expect { subject.execute }.to change { user.keys.where(params).count }.by(1)
  end

  describe 'organization_id handling' do
    it 'sets organization_id from user when not provided' do
      key = subject.execute

      expect(key).to be_persisted
      expect(key.organization_id).to eq(user.organization_id)
    end

    it 'uses explicitly provided organization_id' do
      other_organization = create(:organization)
      service = described_class.new(user, params.merge(organization: other_organization))

      key = service.execute

      expect(key).to be_persisted
      expect(key.organization_id).to eq(other_organization.id)
    end
  end

  context 'internal event tracking' do
    it 'tracks create_ssh_key event when key is persisted' do
      expect { subject.execute }.to trigger_internal_events('create_ssh_key')
        .with(
          user: user,
          additional_properties: {
            creation_source: 'unknown',
            usage_type: 'auth_and_signing'
          }
        )
        .and increment_usage_metrics(
          'counts.count_total_ssh_key_created',
          'counts.count_total_ssh_key_created_28d',
          'counts.count_total_ssh_key_created_7d',
          'redis_hll_counters.count_distinct_user_id_from_create_ssh_key_28d',
          'redis_hll_counters.count_distinct_user_id_from_create_ssh_key_7d'
        )
    end

    context 'when creation_source is ui' do
      subject { described_class.new(user, params.merge(creation_source: 'ui')) }

      it 'tracks the specified creation_source' do
        expect { subject.execute }.to trigger_internal_events('create_ssh_key')
          .with(
            user: user,
            additional_properties: {
              creation_source: 'ui',
              usage_type: 'auth_and_signing'
            }
          )
      end
    end

    context 'when usage_type is auth' do
      subject { described_class.new(user, params.merge(usage_type: 'auth')) }

      it 'tracks the correct usage_type' do
        expect { subject.execute }.to trigger_internal_events('create_ssh_key')
          .with(
            user: user,
            additional_properties: {
              creation_source: 'unknown',
              usage_type: 'auth'
            }
          )
      end
    end

    context 'when usage_type is signing' do
      subject { described_class.new(user, params.merge(usage_type: 'signing')) }

      it 'tracks the correct usage_type' do
        expect { subject.execute }.to trigger_internal_events('create_ssh_key')
          .with(
            user: user,
            additional_properties: {
              creation_source: 'unknown',
              usage_type: 'signing'
            }
          )
      end
    end

    context 'when key is invalid' do
      before do
        allow_next_instance_of(Key) do |key|
          allow(key).to receive(:persisted?).and_return(false)
        end
      end

      it 'does not track the event' do
        expect { subject.execute }.not_to trigger_internal_events('create_ssh_key')
      end
    end
  end
end
