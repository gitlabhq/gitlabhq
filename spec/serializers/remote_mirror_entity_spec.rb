# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrorEntity do
  let(:remote_mirror) { build_stubbed(:remote_mirror, url: "https://test:password@gitlab.com") }
  let(:entity) { described_class.new(remote_mirror) }

  subject { entity.as_json }

  it 'exposes remote-mirror-specific elements' do
    is_expected.to include(
      :id, :url, :enabled, :auth_method,
      :ssh_known_hosts, :ssh_public_key, :ssh_known_hosts_fingerprints
    )
  end

  it 'does not expose password information' do
    expect(subject[:url]).not_to include('password')
    expect(subject[:url]).to eq(remote_mirror.safe_url)
  end
end
