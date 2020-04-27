# frozen_string_literal: true

require 'spec_helper'

describe RemoteMirrorEntity do
  let(:project) { create(:project, :repository, :remote_mirror, url: "https://test:password@gitlab.com") }
  let(:remote_mirror) { project.remote_mirrors.first }
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
