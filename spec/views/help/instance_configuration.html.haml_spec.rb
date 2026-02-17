# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'help/instance_configuration', feature_category: :configuration do
  describe 'General Sections:' do
    let(:instance_configuration) { build(:instance_configuration) }
    let(:settings) { instance_configuration.settings }
    let(:ssh_settings) { settings[:ssh_algorithms_hashes] }

    before do
      create(:plan, name: 'premium')
      assign(:instance_configuration, instance_configuration)
    end

    it 'has links to several sections' do
      render

      expect(rendered).to have_link(nil, href: '#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_link(nil, href: '#gitlab-pages')
      expect(rendered).to have_link(nil, href: '#size-limits')
      expect(rendered).to have_link(nil, href: '#package-registry')
      expect(rendered).to have_link(nil, href: '#rate-limits')
      expect(rendered).to have_link(nil, href: '#files-api-rate-limits')
      expect(rendered).to have_link(nil, href: '#users-api-rate-limits')
      expect(rendered).to have_link(nil, href: '#groups-api-rate-limits')
      expect(rendered).to have_link(nil, href: '#projects-api-rate-limits')
      expect(rendered).to have_link(nil, href: '#ci-cd-limits')
      expect(rendered).to have_link(nil, href: '#organizations-api-rate-limits')
    end

    it 'has several sections' do
      render

      expect(rendered).to have_css('h2#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_css('h2#gitlab-pages')
      expect(rendered).to have_css('h2#size-limits')
      expect(rendered).to have_css('h2#package-registry')
      expect(rendered).to have_css('h2#rate-limits')
      expect(rendered).to have_css('h2#files-api-rate-limits')
      expect(rendered).to have_css('h2#users-api-rate-limits')
      expect(rendered).to have_css('h2#groups-api-rate-limits')
      expect(rendered).to have_css('h2#projects-api-rate-limits')
      expect(rendered).to have_css('h2#ci-cd-limits')
      expect(rendered).to have_css('h2#organizations-api-rate-limits')
    end

    context 'when create_organization_api_limit is nil' do
      let(:instance_configuration_with_nil_org_limit) do
        config = build(:instance_configuration)

        mock_settings = Gitlab::CurrentSettings.current_application_settings.dup
        mock_settings[:create_organization_api_limit] = nil

        allow(config).to receive(:application_settings).and_return(mock_settings)
        config
      end

      before do
        assign(:instance_configuration, instance_configuration_with_nil_org_limit)
      end

      it 'renders "-" for organizations API rate limit when limit is nil' do
        render

        within '#organizations-api-rate-limits' do
          expect(rendered).to have_content('POST /organizations')
          expect(rendered).to have_content('-')
        end
      end
    end

    context 'when organization_switching feature flag is disabled' do
      before do
        stub_feature_flags(organization_switching: false)
      end

      it 'does not have link to organizations API rate limits section' do
        render

        expect(rendered).not_to have_link(nil, href: '#organizations-api-rate-limits')
      end

      it 'does not have organizations API rate limits section' do
        render

        expect(rendered).not_to have_css('h2#organizations-api-rate-limits')
      end
    end
  end
end
