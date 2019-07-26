# frozen_string_literal: true

require 'spec_helper'

describe SystemHookUrlValidator do
  include_examples 'url validator examples', AddressableUrlValidator::DEFAULT_OPTIONS[:schemes]

  context 'by default' do
    let(:validator) { described_class.new(attributes: [:link_url]) }
    let!(:badge) { build(:badge, link_url: 'http://www.example.com') }

    subject { validator.validate(badge) }

    it 'blocks urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).to be_present
    end

    it 'blocks urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).to be_present
    end
  end

  context 'when local requests are allowed' do
    let(:validator) { described_class.new(attributes: [:link_url]) }
    let!(:badge) { build(:badge, link_url: 'http://www.example.com') }
    let!(:settings) { create(:application_setting) }

    subject { validator.validate(badge) }

    before do
      stub_application_setting(allow_local_requests_from_system_hooks: true)
    end

    it 'does not block urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).not_to be_present
    end

    it 'does not block urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).not_to be_present
    end
  end
end
