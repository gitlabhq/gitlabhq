# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubOrgEntity do
  let(:org_data) do
    {
      'id' => 12345,
      'login' => 'org-name',
      'url' => 'https://api.github.com/orgs/org-name',
      'avatar_url' => 'https://avatars.githubusercontent.com/u/12345?v=4',
      'node_id' => 'O_teStT',
      'description' => ''
    }
  end

  subject { described_class.new(org_data).as_json }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(
      :description,
      :name
    )
  end
end
