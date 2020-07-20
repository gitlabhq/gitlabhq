# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Maven::CreatePackageService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:app_name) { 'my-app' }
  let(:version) { '1.0-SNAPSHOT' }
  let(:path) { "my/company/app/#{app_name}" }
  let(:path_with_version) { "#{path}/#{version}" }

  describe '#execute' do
    subject(:package) { described_class.new(project, user, params).execute }

    context 'with version' do
      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

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

      it_behaves_like 'assigns build to package'
    end

    context 'without version' do
      let(:params) do
        {
          path: path,
          name: path,
          version: nil
        }
      end

      it 'creates a new package with metadatum' do
        package = described_class.new(project, user, params).execute

        expect(package).to be_valid
        expect(package.name).to eq(path)
        expect(package.version).to be nil
        expect(package.maven_metadatum).to be_valid
        expect(package.maven_metadatum.path).to eq(path)
        expect(package.maven_metadatum.app_group).to eq('my.company.app')
        expect(package.maven_metadatum.app_name).to eq(app_name)
        expect(package.maven_metadatum.app_version).to be nil
      end
    end

    context 'path is missing' do
      let(:params) do
        {
          name: path,
          version: version
        }
      end

      it 'raises an error' do
        service = described_class.new(project, user, params)

        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
