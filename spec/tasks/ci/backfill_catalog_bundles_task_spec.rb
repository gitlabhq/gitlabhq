# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tasks/ci/backfill_catalog_bundles_task'

RSpec.describe Tasks::Ci::BackfillCatalogBundlesTask, feature_category: :pipeline_composition do
  let!(:maintained_resource) { create(:ci_catalog_resource, :published, verification_level: :gitlab_maintained) }
  let!(:unpublished_resource) { create(:ci_catalog_resource, verification_level: :gitlab_maintained) }
  let!(:unverified_resource) { create(:ci_catalog_resource, :published, verification_level: :unverified) }

  let!(:first_version) { create(:ci_catalog_resource_version, catalog_resource: maintained_resource) }
  let!(:second_version) do
    create(:ci_catalog_resource_version, catalog_resource: maintained_resource, semver: '1.1.0')
  end

  let!(:version_without_semver) do
    create(:ci_catalog_resource_version, catalog_resource: maintained_resource, semver: '2.0.0').tap do |version|
      version.update_columns(semver_major: nil, semver_minor: nil, semver_patch: nil)
    end
  end

  let!(:unpublished_version) { create(:ci_catalog_resource_version, catalog_resource: unpublished_resource) }
  let!(:unverified_version) { create(:ci_catalog_resource_version, catalog_resource: unverified_resource) }

  let(:responses) { {} }
  let(:collected_ids) { [] }

  subject(:execute) { described_class.new.execute }

  before do
    allow(::Ci::Catalog::BundledResources::CollectAndStoreService).to receive(:new) do |version|
      collected_ids << version.id

      instance_double(::Ci::Catalog::BundledResources::CollectAndStoreService).tap do |service|
        allow(service).to receive(:execute) do
          response = responses.fetch(version.id, ServiceResponse.success)
          raise response if response.is_a?(Exception)

          response
        end
      end
    end
  end

  it 'collects every version of published GitLab-maintained resources that has a semver' do
    expect { execute }.to output("2 succeeded, 0 rejected, 0 errored\n").to_stdout

    expect(collected_ids).to contain_exactly(first_version.id, second_version.id)
  end

  context 'when collection rejects a version' do
    let(:responses) do
      { first_version.id => ServiceResponse.error(message: 'Catalog resource is not public', reason: :not_public) }
    end

    it 'reports the rejection and collects the other versions' do
      expect { execute }.to output(
        "#{first_version.project.full_path}@1.0.0: not_public: Catalog resource is not public\n" \
          "1 succeeded, 1 rejected, 0 errored\n"
      ).to_stdout

      expect(collected_ids).to contain_exactly(first_version.id, second_version.id)
    end
  end

  context 'when collection raises for a version' do
    let(:responses) { { first_version.id => StandardError.new('object storage is unavailable') } }

    it 'reports the error, collects the other versions, then aborts' do
      expect { execute }.to raise_error(SystemExit).and output(
        "#{first_version.project.full_path}@1.0.0: StandardError: object storage is unavailable\n" \
          "1 succeeded, 0 rejected, 1 errored\n"
      ).to_stdout

      expect(collected_ids).to contain_exactly(first_version.id, second_version.id)
    end
  end
end
