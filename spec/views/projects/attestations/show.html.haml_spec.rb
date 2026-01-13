# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/attestations/show.html.haml', feature_category: :artifact_security do
  let_it_be(:project) { create(:project, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs persisted associations for attestations
  let_it_be(:attestation) { create(:supply_chain_attestation, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs persisted associations to get all the details
  let_it_be(:build) { attestation.build }
  let_it_be(:user) { project.first_owner }

  before do
    sign_in(user)
    assign(:project, project)
  end

  describe 'when attestation does not exist' do
    before do
      assign(:attestations, nil)
      assign(:attestation_iid_param, '123')
    end

    it 'renders the empty state' do
      render

      expect(rendered).not_to have_selector('[data-testid="attestation-details"]')
      expect(rendered).to have_content('This attestation does not exist')
      expect(rendered).to have_link('View SLSA Component documentation', href: 'https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts')
    end
  end

  describe 'when metadata does not exist' do
    before do
      assign(:attestation, attestation)
      assign(:attestation_iid_param, '123')
      assign(:subjects, [])
    end

    it 'renders error message' do
      render

      expect(rendered).not_to have_selector('[data-testid="attestation-details"]')
      expect(rendered).to have_content('Unable to parse attestation metadata')
      expect(rendered).to have_link('View job for this attestation', href: project_job_path(project, build))
    end
  end

  describe 'when certificate does not exist' do
    before do
      assign(:attestation, attestation)
      assign(:attestation_iid_param, '123')
      assign(:subjects, [{
        'name' => 'demodemo.gem',
        'digest' => { 'sha256' => 'e6e5f634effc310a2a38bea8f71fec08eca20489763628a6e66951265df2177c' }
      }])
      assign(:certificate, {})
    end

    it 'renders error message' do
      render

      expect(rendered).not_to have_selector('[data-testid="certificate-table"]')
      expect(rendered).to have_content('Unable to parse attestation certificate')
    end
  end

  describe 'when all attestation data are available' do
    before do
      assign(:attestation, attestation)
      assign(:attestation_iid_param, attestation.iid)
      assign(:subjects, [{
        'name' => 'demodemo.gem',
        'digest' => { 'sha256' => 'e6e5f634effc310a2a38bea8f71fec08eca20489763628a6e66951265df2177c' }
      }])
      assign(:certificate, {
        build_config_uri: 'http://gdk.test:3000/demos/slsa-verification-project//.gitlab-ci.yml@refs/heads/main',
        build_config_digest: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac',
        build_signer_uri: 'http://gdk.test:3000/demos/slsa-verification-project//.gitlab-ci.yml@refs/heads/main',
        build_signer_digest: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac',
        build_trigger: 'push',
        issuer: 'http://gdk.test:3000',
        runner_environment: 'gitlab-hosted',
        runner_invocation_uri: 'http://gitlab.com/demos/slsa-verification-project/-/jobs/369',
        source_repository_digest: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac',
        source_repository_identifier: '22',
        source_repository_owner_identifier: '95',
        source_repository_owner_uri: 'http://gitlab.com/demos',
        source_repository_ref: 'refs/heads/main',
        source_repository_uri: 'http://gitlab.com/demos/slsa-verification-project',
        source_repository_visibility: 'public'
      })
    end

    it 'renders download link' do
      render

      expect(rendered).to have_selector('[data-testid="attestation-details"]')
      expect(rendered).to have_link(href: download_namespace_project_attestation_path({
        namespace_id: project.namespace, project_id: project, id: attestation.iid
      }))
    end

    it 'renders attestation details' do
      render

      within("[data-testid='attestation-table']") do
        timestamp = attestation.created_at.strftime('%a, %b %d %Y %H:%M:%S %Z')

        expect(rendered).to have_content(attestation.predicate_type)
        expect(rendered).to have_content("#{time_ago_in_words(attestation.created_at)} ago (#{timestamp})")
        expect(rendered).to have_link(build.commit.id, href: project_commit_path(project, build.commit))
        expect(rendered).to have_link(build.iid, href: project_job_path(project, build))
      end
    end

    it 'renders subjects details' do
      render

      within("[data-testid='subjects-table']") do
        expect(rendered).to have_content('demodemo.gem')
        expect(rendered).to have_content('sha:e6e5f634effc310a2a38bea8f71fec08eca20489763628a6e66951265df2177c')
      end
    end

    it 'renders certificate details' do
      render

      within("[data-testid='certificate-table']") do
        expect(rendered).to have_content("[data-testid='build_config_uri']", text: 'http://gdk.test:3000/demos/slsa-verification-project//.gitlab-ci.yml@refs/heads/main')
        expect(rendered).to have_content("[data-testid='build_config_digest']",
          text: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac')
        expect(rendered).to have_content("[data-testid='build_signer_uri']", text: 'http://gdk.test:3000/demos/slsa-verification-project//.gitlab-ci.yml@refs/heads/main')
        expect(rendered).to have_content("[data-testid='build_signer_digest']",
          text: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac')
        expect(rendered).to have_content("[data-testid='build_trigger']", text: 'push')
        expect(rendered).to have_content("[data-testid='issuer']", text: 'http://gdk.test:3000')
        expect(rendered).to have_content("[data-testid='runner_environment']", text: 'gitlab-hosted')
        expect(rendered).to have_content("[data-testid='runner_invocation_uri']", text: 'http://gitlab.com/demos/slsa-verification-project/-/jobs/369')
        expect(rendered).to have_content("[data-testid='source_repository_digest']",
          text: 'd75a96b5aac98f80970bec5d57819d67a8a1d7ac')
        expect(rendered).to have_content("[data-testid='source_repository_identifier']", text: '22')
        expect(rendered).to have_content("[data-testid='source_repository_owner_identifier']", text: '95')
        expect(rendered).to have_content("[data-testid='source_repository_owner_uri']", text: 'http://gitlab.com/demos')
        expect(rendered).to have_content("[data-testid='source_repository_ref']", text: 'refs/heads/main')
        expect(rendered).to have_content("[data-testid='source_repository_uri']", text: 'http://gitlab.com/demos/slsa-verification-project')
        expect(rendered).to have_content("[data-testid='source_repository_visibility']", text: 'public')
      end
    end
  end
end
