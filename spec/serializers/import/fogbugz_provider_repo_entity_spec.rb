# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::FogbugzProviderRepoEntity do
  let(:provider_url) { 'https://demo.fogbugz.com/' }
  let(:repo_data) do
    {
      'ixProject' => 'foo',
      'sProject' => 'demo'
    }
  end

  let(:repo) { Gitlab::FogbugzImport::Repository.new(repo_data) }

  subject { described_class.represent(repo, { provider_url: provider_url }).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: 'foo',
        full_name: 'demo',
        sanitized_name: 'demo',
        provider_link: 'https://demo.fogbugz.com/demo'
      }
    end
  end
end
