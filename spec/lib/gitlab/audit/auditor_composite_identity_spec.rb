# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Auditor, ':request_store enabled composite identity',
  :request_store, feature_category: :audit_events do
  let_it_be(:project) { create(:project) }
  let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }
  let_it_be(:service_account) { create(:user, :ai_service_account) }
  let_it_be(:human) { create(:user) }

  let(:context) do
    {
      name: 'audit_operation',
      author: author,
      scope: project,
      target: feature_flag,
      message: 'Audited something'
    }
  end

  before do
    allow(Gitlab::Audit::Type::Definition).to receive(:defined?).and_return(true)
  end

  subject(:emitted_event) { emit_audit_event }

  def emit_audit_event
    described_class.audit(context)

    AuditEvents::ProjectAuditEvent.order(id: :desc).first
  end

  context 'when the author is a service account acting on behalf of a human' do
    let(:author) { human }

    before do
      Gitlab::Auth::Identity.link_from_scoped_user(service_account, human, context: :authentication)
    end

    it 'attributes the persisted event to the service account and records human author details',
      :aggregate_failures do
      expect(emitted_event.author_id).to eq(service_account.id)
      expect(emitted_event.author_name).to eq("#{service_account.name} on behalf of #{human.to_reference}")
      expect(emitted_event.details).to include(
        human_author_id: human.id,
        human_author_name: human.name,
        human_author_username: human.username
      )
    end
  end

  context 'when the service account is linked in the permission_check context' do
    let(:author) { human }

    before do
      Gitlab::Auth::Identity.link_from_scoped_user(service_account, human, context: :permission_check)
    end

    it 'keeps the persisted event attributed to the human without human_author details', :aggregate_failures do
      expect(emitted_event.author_id).to eq(human.id)
      expect(emitted_event.author_name).to eq(human.name)
      expect(emitted_event.details.keys).not_to include(:human_author_id, :human_author_name, :human_author_username)
    end
  end

  context 'when the author is a deploy token whose id collides with the linked human id' do
    let(:deploy_token) { build(:deploy_token, id: human.id) }
    let(:author) { deploy_token }
    let(:context) { super().merge(ip_address: '127.0.0.1') }

    before do
      Gitlab::Auth::Identity.link_from_scoped_user(service_account, human, context: :authentication)
    end

    it 'does not attribute the event to the service account', :aggregate_failures do
      expect(emitted_event.author_id).to eq(Gitlab::Audit::NullAuthor::DEPLOY_TOKEN_AUTHOR_ID)
      expect(emitted_event.details.keys).not_to include(:human_author_id, :human_author_name, :human_author_username)
    end
  end

  context 'when the author is a regular user' do
    let(:author) { human }

    it 'attributes the persisted event to that user without human_author details', :aggregate_failures do
      expect(emitted_event.author_id).to eq(human.id)
      expect(emitted_event.details.keys).not_to include(:human_author_id, :human_author_name, :human_author_username)
    end
  end
end
