# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Maven::CreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:app_name) { 'my-app' }
  let(:version) { '1.0-SNAPSHOT' }
  let(:path) { "my/company/app/#{app_name}" }
  let(:path_with_version) { "#{path}/#{version}" }

  describe '#execute' do
    let(:package) { subject[:package] }

    subject { described_class.new(project, user, params).execute }

    context 'with version' do
      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

      it_behaves_like 'returning a success service response'

      it 'creates a new package with metadatum' do
        expect(package).to be_valid
        expect(package.name).to eq(path)
        expect(package.version).to eq(version)
        expect(package.package_type).to eq('maven')
        expect(package.maven_metadatum).to be_valid
        expect(package.maven_metadatum.path).to eq(path_with_version)
        expect(package.maven_metadatum.app_group).to eq('my.company.app')
        expect(package.maven_metadatum.app_name).to eq(app_name)
        expect(package.maven_metadatum.app_version).to eq(version)
      end

      it_behaves_like 'assigns the package creator'

      context 'with FF maven_extract_package_model disabled' do
        before do
          stub_feature_flags(maven_extract_package_model: false)
        end

        it_behaves_like 'returning a success service response'

        it 'creates a new package with metadatum' do
          expect(package).to be_valid
          expect(package.name).to eq(path)
          expect(package.version).to eq(version)
          expect(package.package_type).to eq('maven')
          expect(package.maven_metadatum).to be_valid
          expect(package.maven_metadatum.path).to eq(path_with_version)
          expect(package.maven_metadatum.app_group).to eq('my.company.app')
          expect(package.maven_metadatum.app_name).to eq(app_name)
          expect(package.maven_metadatum.app_version).to eq(version)
        end
      end
    end

    context 'without version' do
      let(:params) do
        {
          path: path,
          name: path,
          version: nil
        }
      end

      it_behaves_like 'returning a success service response'

      it 'creates a new package with metadatum' do
        expect(package).to be_valid
        expect(package.name).to eq(path)
        expect(package.version).to be nil
        expect(package.maven_metadatum).to be_valid
        expect(package.maven_metadatum.path).to eq(path)
        expect(package.maven_metadatum.app_group).to eq('my.company.app')
        expect(package.maven_metadatum.app_name).to eq(app_name)
        expect(package.maven_metadatum.app_version).to be nil
      end

      it_behaves_like 'assigns the package creator'
    end

    context 'without path' do
      let(:params) do
        {
          name: path,
          version: version
        }
      end

      it_behaves_like 'returning an error service response',
        message: "Validation failed: Maven metadatum path can't be blank" do
        it { is_expected.to have_attributes(reason: :invalid_parameter) }
      end
    end

    context 'with an exisiting package' do
      let!(:package) { create(:maven_package, project: project, name: path, version: version) }

      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

      it_behaves_like 'returning an error service response',
        message: 'Validation failed: Name has already been taken' do
        it { is_expected.to have_attributes(reason: :name_taken) }
      end
    end
  end
end
