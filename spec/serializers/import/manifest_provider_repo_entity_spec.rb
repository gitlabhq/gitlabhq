# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ManifestProviderRepoEntity do
  let(:current_user) { create(:user) }
  let(:request) { double(:request, current_user: current_user) }
  let(:repo_data) do
    {
      id: 1,
      url: 'http://demo.repo/url',
      path: '/demo/path'
    }
  end

  subject { described_class.represent(repo_data, { group_full_path: 'group', request: request }).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: repo_data[:id],
        full_name: repo_data[:url],
        sanitized_name: nil,
        provider_link: repo_data[:url]
      }
    end
  end
end
