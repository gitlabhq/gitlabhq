# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubishProviderRepoEntity do
  let(:provider_url) { 'https://github.com/' }
  let(:repo) do
    {
      id: 1,
      full_name: 'full/name',
      name: 'name'
    }
  end

  subject { described_class.represent(repo, { provider_url: provider_url }).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: 1,
        full_name: 'full/name',
        sanitized_name: 'name',
        provider_link: 'https://github.com/full/name'
      }
    end
  end
end
