# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Composer::CacheUpdateWorker, type: :worker do
  describe '#perform' do
    let_it_be(:package_name) { 'sample-project' }
    let_it_be(:json) { { 'name' => package_name } }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }

    let(:last_sha) { nil }
    let!(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
    let(:job_args) { [project.id, package_name, last_sha] }

    subject { described_class.new.perform(*job_args) }

    before do
      stub_composer_cache_object_storage
    end

    include_examples 'an idempotent worker' do
      context 'creating a package' do
        it 'updates the cache' do
          expect { subject }.to change { Packages::Composer::CacheFile.count }.by(1)
        end
      end

      context 'deleting a package' do
        let!(:last_sha) do
          Gitlab::Composer::Cache.new(project: project, name: package_name).execute
          package.reload.composer_metadatum.version_cache_sha
        end

        before do
          package.destroy!
        end

        it 'marks the file for deletion' do
          expect { subject }.not_to change { Packages::Composer::CacheFile.count }

          cache_file = Packages::Composer::CacheFile.last

          expect(cache_file.reload.delete_at).not_to be_nil
        end
      end
    end
  end
end
