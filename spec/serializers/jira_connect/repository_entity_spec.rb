# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::RepositoryEntity, feature_category: :integrations do
  subject(:serializer) { described_class.represent(repository).as_json }

  let(:repository) { build_stubbed(:project) }

  it 'contains all necessary elements of the project' do
    expect(serializer[:id]).to eq(repository.id)
    expect(serializer[:name]).to eq(repository.name)
    expect(serializer[:url]).to end_with(repository.full_path)
    expect(serializer[:avatarUrl]).to eq(repository.avatar_url)
    expect(serializer[:updateSequenceId]).to be_kind_of(Integer)
    expect(serializer[:lastUpdatedDate]).to eq(repository.updated_at.iso8601)
    expect(serializer[:workspace]).to be_kind_of(Hash)
  end
end
