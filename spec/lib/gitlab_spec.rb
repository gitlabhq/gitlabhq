require 'rails_helper'

describe Gitlab do
  describe '.com?' do
    it 'is true when on GitLab.com' do
      stub_config_setting(url: 'https://gitlab.com')

      expect(described_class.com?).to eq true
    end

    it 'is true when on staging' do
      stub_config_setting(url: 'https://staging.gitlab.com')

      expect(described_class.com?).to eq true
    end

    it 'is true when on other gitlab subdomain' do
      stub_config_setting(url: 'https://example.gitlab.com')
<<<<<<< HEAD
=======

      expect(described_class.com?).to eq true
>>>>>>> upstream/master
    end

    it 'is false when not on GitLab.com' do
      stub_config_setting(url: 'http://example.com')

      expect(described_class.com?).to eq false
    end
  end
end
