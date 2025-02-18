# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::CreatePackageService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:package_name) { 'composer-package-name' }
  let_it_be(:json) { { name: package_name }.to_json }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json }) }
  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      branch: branch,
      tag: tag
    }
  end

  describe '#execute' do
    let(:tag) { nil }
    let(:branch) { nil }

    subject { described_class.new(project, user, params).execute }

    let(:created_package) { ::Packages::Composer::Package.last }

    context 'without an existing package' do
      context 'with a branch' do
        let(:branch) { project.repository.find_branch('master') }

        it 'creates the package' do
          expect { subject }
            .to change { ::Packages::Composer::Package.count }.by(1)
            .and change { Packages::Composer::Metadatum.count }.by(1)

          expect(created_package.name).to eq package_name
          expect(created_package.version).to eq 'dev-master'
          expect(created_package.composer_metadatum.target_sha).to eq branch.target
          expect(created_package.composer_metadatum.composer_json.to_json).to eq json
        end

        it_behaves_like 'assigns the package creator' do
          let(:package) { created_package }
        end

        it_behaves_like 'assigns build to package'
        it_behaves_like 'assigns status to package'
      end

      context 'with a tag' do
        let(:tag) { project.repository.find_tag('v1.2.3') }

        before_all do
          project.repository.add_tag(user, 'v1.2.3', 'master')
        end

        it 'creates the package' do
          expect { subject }
            .to change { ::Packages::Composer::Package.count }.by(1)
            .and change { Packages::Composer::Metadatum.count }.by(1)

          expect(created_package.name).to eq package_name
          expect(created_package.version).to eq '1.2.3'
        end

        it_behaves_like 'assigns the package creator' do
          let(:package) { created_package }
        end

        it_behaves_like 'assigns build to package'
        it_behaves_like 'assigns status to package'
      end
    end

    context 'with an existing package' do
      let(:branch) { project.repository.find_branch('master') }

      context 'belonging to the same project' do
        before do
          described_class.new(project, user, params).execute
        end

        it 'does not create a new package' do
          expect { subject }
            .to change { ::Packages::Composer::Package.count }.by(0)
            .and change { Packages::Composer::Metadatum.count }.by(0)
        end
      end

      context 'belonging to another project' do
        let(:other_project) { create(:project) }
        let!(:other_package) { create(:composer_package, name: package_name, version: 'dev-master', project: other_project) }

        it 'fails with an error' do
          expect { subject }
            .to raise_error(/is already taken/)
        end

        context 'with pending_destruction package' do
          let!(:other_package) { create(:composer_package, :pending_destruction, name: package_name, version: 'dev-master', project: other_project) }

          it 'creates the package' do
            expect { subject }
              .to change { ::Packages::Composer::Package.count }.by(1)
              .and change { Packages::Composer::Metadatum.count }.by(1)
          end
        end
      end

      context 'same name but of different type' do
        let(:other_project) { create(:project) }
        let!(:other_package) { create(:generic_package, name: package_name, version: 'dev-master', project: other_project) }

        it 'creates the package' do
          expect { subject }
            .to change { ::Packages::Composer::Package.count }.by(1)
            .and change { Packages::Composer::Metadatum.count }.by(1)
        end
      end
    end
  end
end
