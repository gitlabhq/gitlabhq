# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'help/instance_configuration' do
  describe 'General Sections:' do
    let(:instance_configuration) { build(:instance_configuration) }
    let(:settings) { instance_configuration.settings }
    let(:ssh_settings) { settings[:ssh_algorithms_hashes] }

    before do
      create(:plan, name: 'plan1', title: 'Plan 1')
      assign(:instance_configuration, instance_configuration)
    end

    it 'has links to several sections' do
      render

      expect(rendered).to have_link(nil, href: '#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_link(nil, href: '#gitlab-pages')
      expect(rendered).to have_link(nil, href: '#size-limits')
      expect(rendered).to have_link(nil, href: '#package-registry')
      expect(rendered).to have_link(nil, href: '#rate-limits')
      expect(rendered).to have_link(nil, href: '#ci-cd-limits')
    end

    it 'has several sections' do
      render

      expect(rendered).to have_css('h2#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_css('h2#gitlab-pages')
      expect(rendered).to have_css('h2#size-limits')
      expect(rendered).to have_css('h2#package-registry')
      expect(rendered).to have_css('h2#rate-limits')
      expect(rendered).to have_css('h2#ci-cd-limits')
    end
  end
end
