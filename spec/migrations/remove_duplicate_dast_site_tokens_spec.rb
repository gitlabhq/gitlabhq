# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveDuplicateDastSiteTokens, feature_category: :dynamic_application_security_testing do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:dast_site_tokens) { table(:dast_site_tokens) }
  let!(:namespace) { namespaces.create!(id: 1, name: 'group', path: 'group') }
  let!(:project1) { projects.create!(id: 1, namespace_id: namespace.id, path: 'project1') }
  # create non duplicate dast site token
  let!(:dast_site_token1) { dast_site_tokens.create!(project_id: project1.id, url: 'https://gitlab.com', token: SecureRandom.uuid) }

  context 'when duplicate dast site tokens exists' do
    # create duplicate dast site token
    let!(:duplicate_url) { 'https://about.gitlab.com' }

    let!(:project2) { projects.create!(id: 2, namespace_id: namespace.id, path: 'project2') }
    let!(:dast_site_token2) { dast_site_tokens.create!(project_id: project2.id, url: duplicate_url, token: SecureRandom.uuid) }
    let!(:dast_site_token3) { dast_site_tokens.create!(project_id: project2.id, url: 'https://temp_url.com', token: SecureRandom.uuid) }
    let!(:dast_site_token4) { dast_site_tokens.create!(project_id: project2.id, url: 'https://other_temp_url.com', token: SecureRandom.uuid) }

    before 'update URL to bypass uniqueness validation' do
      dast_site_tokens.where(project_id: 2).update_all(url: duplicate_url)
    end

    describe 'migration up' do
      it 'does remove duplicated dast site tokens' do
        expect(dast_site_tokens.count).to eq(4)
        expect(dast_site_tokens.where(project_id: 2, url: duplicate_url).size).to eq(3)

        migrate!

        expect(dast_site_tokens.count).to eq(2)
        expect(dast_site_tokens.where(project_id: 2, url: duplicate_url).size).to eq(1)
      end
    end
  end

  context 'when duplicate dast site tokens does not exists' do
    before do
      dast_site_tokens.create!(project_id: 1, url: 'https://about.gitlab.com/handbook', token: SecureRandom.uuid)
    end

    describe 'migration up' do
      it 'does remove duplicated dast site tokens' do
        expect { migrate! }.not_to change(dast_site_tokens, :count)
      end
    end
  end
end
