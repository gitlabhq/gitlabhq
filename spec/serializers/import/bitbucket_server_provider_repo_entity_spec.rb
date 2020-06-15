# frozen_string_literal: true

require 'spec_helper'

describe Import::BitbucketServerProviderRepoEntity do
  let(:repo_data) do
    {
      'name' => 'test',
      'project' => {
        'name' => 'demo'
      },
      'links' => {
        'self' => [
          {
            'href' => 'http://local.bitbucket.server/demo/test.git',
            'name' => 'http'
          }
        ]
      }
    }
  end
  let(:repo) { BitbucketServer::Representation::Repo.new(repo_data) }

  subject { described_class.new(repo).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: 'demo/test',
        full_name: 'demo/test',
        sanitized_name: 'test',
        provider_link: 'http://local.bitbucket.server/demo/test.git'
      }
    end
  end
end
