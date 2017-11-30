require 'spec_helper'

describe GeoProjectRegistryEntity, :postgresql do
  let(:registry) { create(:geo_project_registry, :synced) }

  let(:entity) do
    described_class.new(registry, request: double)
  end

  subject { entity.as_json }

  it { is_expected.to have_key(:project_id) }
  it { is_expected.to have_key(:last_repository_synced_at) }
  it { is_expected.to have_key(:last_repository_successful_sync_at) }
  it { is_expected.to have_key(:last_wiki_synced_at) }
  it { is_expected.to have_key(:last_wiki_successful_sync_at) }
  it { is_expected.to have_key(:repository_retry_count) }
  it { is_expected.to have_key(:wiki_retry_count) }
  it { is_expected.to have_key(:last_repository_sync_failure) }
  it { is_expected.to have_key(:last_wiki_sync_failure) }
end
