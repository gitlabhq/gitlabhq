require 'rails_helper'

describe 'help/instance_configuration' do
  describe 'General Sections:' do
    let(:instance_configuration) { build(:instance_configuration)}
    let(:settings) { instance_configuration.settings }
    let(:ssh_settings) { settings[:ssh_algorithms_hashes] }

    before do
      assign(:instance_configuration, instance_configuration)
    end

    it 'has links to several sections' do
      render

      expect(rendered).to have_link(nil, '#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_link(nil, '#gitlab-pages')
      expect(rendered).to have_link(nil, '#gitlab-ci')
    end

    it 'has several sections' do
      render

      expect(rendered).to have_css('h2#ssh-host-keys-fingerprints') if ssh_settings.any?
      expect(rendered).to have_css('h2#gitlab-pages')
      expect(rendered).to have_css('h2#gitlab-ci')
    end
  end
end
