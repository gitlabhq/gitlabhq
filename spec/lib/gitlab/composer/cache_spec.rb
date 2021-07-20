# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Composer::Cache do
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }

  let(:branch) { project.repository.find_branch('master') }
  let(:sha_regex) { /^[A-Fa-f0-9]{64}$/ }

  shared_examples 'Composer create cache page' do
    let(:expected_json) { ::Gitlab::Composer::VersionIndex.new(packages).to_json }

    before do
      stub_composer_cache_object_storage
    end

    it 'creates the cached page' do
      expect { subject }.to change { Packages::Composer::CacheFile.count }.by(1)
      cache_file = Packages::Composer::CacheFile.last
      expect(cache_file.file_sha256).to eq package.reload.composer_metadatum.version_cache_sha
      expect(cache_file.file.read).to eq expected_json
    end
  end

  shared_examples 'Composer marks cache page for deletion' do
    it 'marks the page for deletion' do
      cache_file = Packages::Composer::CacheFile.last

      freeze_time do
        expect { subject }.to change { cache_file.reload.delete_at}.from(nil).to(1.day.from_now)
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(project: project, name: package_name).execute }

    context 'creating packages' do
      context 'with a pre-existing package' do
        let(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
        let(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
        let(:packages) { [package, package2] }

        before do
          package
          described_class.new(project: project, name: package_name).execute
          package.reload
          package2
        end

        it 'updates the sha and creates the cache page' do
          expect { subject }.to change { package2.reload.composer_metadatum.version_cache_sha }.from(nil).to(sha_regex)
            .and change { package.reload.composer_metadatum.version_cache_sha }.to(sha_regex)
        end

        it_behaves_like 'Composer create cache page'
        it_behaves_like 'Composer marks cache page for deletion'
      end

      context 'first package' do
        let!(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
        let(:packages) { [package] }

        it 'updates the sha and creates the cache page' do
          expect { subject }.to change { package.reload.composer_metadatum.version_cache_sha }.from(nil).to(sha_regex)
        end

        it_behaves_like 'Composer create cache page'
      end
    end

    context 'updating packages' do
      let(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
      let(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
      let(:packages) { [package, package2] }

      before do
        packages

        described_class.new(project: project, name: package_name).execute

        package.update!(version: '1.2.0')
        package.reload
      end

      it_behaves_like 'Composer create cache page'
      it_behaves_like 'Composer marks cache page for deletion'
    end

    context 'deleting packages' do
      context 'when it is not the last package' do
        let(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
        let(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
        let(:packages) { [package] }

        before do
          package
          package2

          described_class.new(project: project, name: package_name).execute

          package2.destroy!
        end

        it_behaves_like 'Composer create cache page'
        it_behaves_like 'Composer marks cache page for deletion'
      end

      context 'when it is the last package' do
        let!(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
        let!(:last_sha) do
          described_class.new(project: project, name: package_name).execute
          package.reload.composer_metadatum.version_cache_sha
        end

        before do
          package.destroy!
        end

        subject { described_class.new(project: project, name: package_name, last_page_sha: last_sha).execute }

        it_behaves_like 'Composer marks cache page for deletion'

        it 'does not create a new page' do
          expect { subject }.not_to change { Packages::Composer::CacheFile.count }
        end
      end
    end
  end
end
