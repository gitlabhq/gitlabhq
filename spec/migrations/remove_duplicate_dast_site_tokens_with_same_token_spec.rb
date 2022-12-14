# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveDuplicateDastSiteTokensWithSameToken, feature_category: :dynamic_application_security_testing do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:dast_site_tokens) { table(:dast_site_tokens) }
  let!(:namespace) { namespaces.create!(id: 1, name: 'group', path: 'group') }
  let!(:project1) { projects.create!(id: 1, namespace_id: namespace.id, path: 'project1') }
  # create non duplicate dast site token
  let!(:dast_site_token1) { dast_site_tokens.create!(project_id: project1.id, url: 'https://gitlab.com', token: SecureRandom.uuid) }

  context 'when duplicate dast site tokens exists' do
    # create duplicate dast site token
    let!(:duplicate_token) { 'duplicate_token' }
    let!(:other_duplicate_token) { 'other_duplicate_token' }

    let!(:project2) { projects.create!(id: 2, namespace_id: namespace.id, path: 'project2') }
    let!(:dast_site_token2) { dast_site_tokens.create!(project_id: project2.id, url: 'https://gitlab2.com', token: duplicate_token) }
    let!(:dast_site_token3) { dast_site_tokens.create!(project_id: project2.id, url: 'https://gitlab3.com', token: duplicate_token) }
    let!(:dast_site_token4) { dast_site_tokens.create!(project_id: project2.id, url: 'https://gitlab4.com', token: duplicate_token) }

    let!(:project3) { projects.create!(id: 3, namespace_id: namespace.id, path: 'project3') }
    let!(:dast_site_token5) { dast_site_tokens.create!(project_id: project3.id, url: 'https://gitlab2.com', token: other_duplicate_token) }
    let!(:dast_site_token6) { dast_site_tokens.create!(project_id: project3.id, url: 'https://gitlab3.com', token: other_duplicate_token) }
    let!(:dast_site_token7) { dast_site_tokens.create!(project_id: project3.id, url: 'https://gitlab4.com', token: other_duplicate_token) }

    describe 'migration up' do
      it 'does remove duplicated dast site tokens with the same token' do
        expect(dast_site_tokens.count).to eq(7)
        expect(dast_site_tokens.where(token: duplicate_token).size).to eq(3)

        migrate!

        expect(dast_site_tokens.count).to eq(3)
        expect(dast_site_tokens.where(token: duplicate_token).size).to eq(1)
      end
    end
  end

  context 'when duplicate dast site tokens do not exist' do
    let!(:dast_site_token5) { dast_site_tokens.create!(project_id: 1, url: 'https://gitlab5.com', token: SecureRandom.uuid) }

    describe 'migration up' do
      it 'does not remove any dast site tokens' do
        expect { migrate! }.not_to change(dast_site_tokens, :count)
      end
    end
  end
end
