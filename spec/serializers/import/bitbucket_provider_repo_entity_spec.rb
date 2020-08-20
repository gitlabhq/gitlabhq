# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketProviderRepoEntity do
  let(:repo_data) do
    {
      'name' => 'repo_name',
      'full_name' => 'owner/repo_name',
      'links' => {
        'clone' => [
          {
            'href' => 'https://bitbucket.org/owner/repo_name',
            'name' => 'https'
          }
        ]
      }
    }
  end

  let(:repo) { Bitbucket::Representation::Repo.new(repo_data) }

  subject { described_class.new(repo).as_json }

  it_behaves_like 'exposes required fields for import entity' do
    let(:expected_values) do
      {
        id: 'owner/repo_name',
        full_name: 'owner/repo_name',
        sanitized_name: 'repo_name',
        provider_link: 'https://bitbucket.org/owner/repo_name'
      }
    end
  end
end
