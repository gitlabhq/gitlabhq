# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GitlabProviderRepoEntity do
  let(:repo_data) do
    {
      'id' => 1,
      'path_with_namespace' => 'demo/test',
      'path' => 'test',
      'web_url' => 'https://gitlab.com/demo/test'
    }
  end

  subject { described_class.new(repo_data).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: 1,
        full_name: 'demo/test',
        sanitized_name: 'test',
        provider_link: 'https://gitlab.com/demo/test'
      }
    end
  end
end
