# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubOrgSerializer do
  it 'represents GithubOrgEntity entities' do
    expect(described_class.entity_class).to eq(Import::GithubOrgEntity)
  end

  describe '#represent' do
    let(:org_data) do
      {
        id: 123456,
        login: 'org-name',
        node_id: 'O_teStT',
        url: 'https://api.github.com/orgs/org-name',
        repos_url: 'https://api.github.com/orgs/org-name/repos',
        events_url: 'https://api.github.com/orgs/org-name/events',
        hooks_url: 'https://api.github.com/orgs/org-name/hooks',
        issues_url: 'https://api.github.com/orgs/org-name/issues',
        members_url: 'https://api.github.com/orgs/org-name/members{/member}',
        public_members_url: 'https://api.github.com/orgs/org-name/public_members{/member}',
        avatar_url: 'avatar_url',
        description: 'description'
      }
    end

    subject { described_class.new.represent(resource) }

    context 'when a single object is being serialized' do
      let(:resource) { org_data }

      it 'serializes organization object' do
        expect(subject).to eq({ name: 'org-name', description: 'description' })
      end
    end

    context 'when multiple objects are being serialized' do
      let(:count) { 3 }
      let(:resource) { Array.new(count, org_data) }

      it 'serializes array of organizations' do
        expect(subject).to all(eq({ name: 'org-name', description: 'description' }))
      end
    end
  end
end
