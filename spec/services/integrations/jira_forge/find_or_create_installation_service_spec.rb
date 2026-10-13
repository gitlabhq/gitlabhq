# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraForge::FindOrCreateInstallationService, feature_category: :integrations do
  let_it_be(:organization) { create(:organization) }

  let(:installation_id) { 'ari:cloud:ecosystem::installation/0a3a7799-53ae-4a5b-9e7e-03338980abb5' }
  let(:cloud_id) { 'cloud-abc' }
  let(:api_base_url) { 'https://api.atlassian.com/ex/jira/cloud-abc' }
  let(:system_token) { 'sys-token' }

  subject(:result) do
    described_class.execute(
      installation_id: installation_id,
      cloud_id: cloud_id,
      organization_id: organization.id,
      jira_api_base_url: api_base_url,
      forge_system_token: system_token
    )
  end

  context 'when no installation exists for the installation id or site' do
    it 'creates a native Forge installation on the organization, forge_direct? immediately' do
      expect { result }.to change { JiraConnectInstallation.count }.by(1)

      expect(result).to have_attributes(
        organization_id: organization.id,
        forge_installation_xid: installation_id,
        cloud_id: cloud_id,
        jira_api_base_url: api_base_url,
        forge_system_token: system_token,
        client_key: nil
      )
      expect(result.forge?).to be(true)
      expect(result.forge_direct?).to be(true)
    end
  end

  context 'when an installation exists for the installation id' do
    let_it_be(:existing) do
      create(:jira_connect_installation, :forge, organization: organization,
        forge_installation_xid: 'ari:cloud:ecosystem::installation/0a3a7799-53ae-4a5b-9e7e-03338980abb5')
    end

    it 'reuses the row and refreshes the Forge system-token context' do
      expect { result }.not_to change { JiraConnectInstallation.count }

      expect(result.id).to eq(existing.id)
      expect(result).to have_attributes(jira_api_base_url: api_base_url, forge_system_token: system_token)
    end

    context 'when the refresh is invalid' do
      let(:api_base_url) { 'not a url' }

      it 'returns the row with errors and keeps the stored context' do
        expect(result.id).to eq(existing.id)
        expect(result.errors).to be_present
        expect(existing.reload.jira_api_base_url).to eq('https://api.atlassian.com/ex/jira/cloud-xyz')
      end
    end
  end

  context 'when a concurrent first link from another organization wins the insert' do
    let_it_be(:other_organization) { create(:organization) }

    it 'refuses without naming the other organization' do
      allow(JiraConnectInstallation).to receive(:create) do
        create(:jira_connect_installation, :forge, organization: other_organization, cloud_id: cloud_id,
          forge_installation_xid: installation_id)
        raise ActiveRecord::RecordNotUnique
      end

      expect(result).not_to be_persisted
      expect(result.errors.full_messages.to_sentence).to eq('This group cannot be linked to this Jira site.')
    end
  end

  context 'when a concurrent first link wins the insert' do
    it 'adopts the winning row instead of raising' do
      allow(JiraConnectInstallation).to receive(:create) do
        create(:jira_connect_installation, :forge, organization: organization, cloud_id: cloud_id,
          forge_installation_xid: installation_id)
        raise ActiveRecord::RecordNotUnique
      end

      expect { result }.to change { JiraConnectInstallation.count }.by(1)

      expect(result).to be_persisted
      expect(result).to have_attributes(
        forge_installation_xid: installation_id, jira_api_base_url: api_base_url, forge_system_token: system_token
      )
    end
  end

  context 'when a Connect installation exists for the site (upgrade path)' do
    let_it_be(:existing) do
      create(:jira_connect_installation, organization: organization, cloud_id: 'cloud-abc')
    end

    it 'reuses the row, backfills the installation id and adds the Forge context' do
      expect { result }.not_to change { JiraConnectInstallation.count }

      expect(result.id).to eq(existing.id)
      expect(result.client_key).to eq(existing.client_key)
      expect(result).to have_attributes(
        forge_installation_xid: installation_id,
        jira_api_base_url: api_base_url,
        forge_system_token: system_token
      )
      expect(result.forge_direct?).to be(true)
    end
  end

  context 'when the site row already carries another installation id (reinstall)' do
    let_it_be(:existing) do
      create(:jira_connect_installation, :forge,
        organization: organization, cloud_id: 'cloud-abc',
        forge_installation_xid: 'ari:cloud:ecosystem::installation/8db33809-1f32-48bb-8c52-5877dab48107')
    end

    it 'creates a new installation instead of hijacking the existing one' do
      expect { result }.to change { JiraConnectInstallation.count }.by(1)

      expect(result.id).not_to eq(existing.id)
      expect(result.forge_installation_xid).to eq(installation_id)
      expect(existing.reload.forge_installation_xid)
        .to eq('ari:cloud:ecosystem::installation/8db33809-1f32-48bb-8c52-5877dab48107')
    end
  end

  context 'when another organization already holds this installation id' do
    let_it_be(:other_organization) { create(:organization) }
    let_it_be(:existing) do
      create(:jira_connect_installation, :forge, organization: other_organization,
        forge_installation_xid: 'ari:cloud:ecosystem::installation/0a3a7799-53ae-4a5b-9e7e-03338980abb5')
    end

    it 'refuses without naming the other organization' do
      expect { result }.not_to change { JiraConnectInstallation.count }

      expect(result).not_to be_persisted
      expect(result.errors.full_messages.to_sentence).to eq('This group cannot be linked to this Jira site.')
    end
  end
end
