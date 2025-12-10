# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/attestations/index.html.haml', feature_category: :artifact_security do
  let_it_be(:project) { create(:project, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs persisted associations for attestations
  let_it_be(:user) { project.first_owner }

  before do
    sign_in(user)
    assign(:project, project)
  end

  describe 'when there are no attestations' do
    before do
      assign(:attestations, [])
    end

    it 'renders the empty state' do
      render

      expect(rendered).not_to have_selector('[data-testid="attestations-table"]')
      expect(rendered).to have_content('Sign and verify SLSA provenance with a CI/CD Component.')
      expect(rendered).to have_link('View SLSA Component documentation', href: 'https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts')
    end
  end

  describe 'when there are attestations' do
    let!(:attestation_success) { create(:supply_chain_attestation, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs persisted associations
    let!(:attestation_error) { create(:supply_chain_attestation, :with_error_status, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs persisted associations
    let!(:paginated_attestations) { SupplyChain::Attestation.for_project(project.id).keyset_paginate(cursor: nil) }

    before do
      assign(:attestations, paginated_attestations)
    end

    it 'renders the table' do
      render
      attestation = attestation_success

      expect(rendered).to have_selector('[data-testid="attestations-table"]')
      within("[data-testid='attestations-#{attestation.iid}']") do
        expect(rendered).to have_content(attestation.file.filename)
        expect(rendered).to have_link(attestation.build.iid, href: project_job_path(project, build))
        expect(rendered).to have_content(attestation.predicate_type)
        expect(rendered).to have_content(attestation.predicate_type)
        expect(rendered).to have_content(l(attestation_success.created_at.to_date, format: :long))
        expect(rendered).to have_link(href: download_namespace_project_attestation_path({
          namespace_id: project.namespace, project_id: project, id: attestation.iid
        }))
      end

      # attestion with success status shows success badge
      within("[data-testid='attestations-#{attestation_success.iid}']") do
        expect(rendered).to have_css('.gl-badge.badge-success')
      end

      # attestion with error status shows danger badge
      within("[data-testid='attestations-#{attestation_error.iid}']") do
        expect(rendered).to have_css('.gl-badge.badge-danger')
      end
    end
  end
end
