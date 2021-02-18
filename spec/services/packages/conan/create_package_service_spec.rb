# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Conan::CreatePackageService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    subject(:package) { service.execute }

    context 'valid params' do
      let(:params) do
        {
          package_name: 'my-pkg',
          package_version: '1.0.0',
          package_username: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path),
          package_channel: 'stable'
        }
      end

      it 'creates a new package' do
        expect(package).to be_valid
        expect(package.name).to eq(params[:package_name])
        expect(package.version).to eq(params[:package_version])
        expect(package.package_type).to eq('conan')
        expect(package.conan_metadatum.package_username).to eq(params[:package_username])
        expect(package.conan_metadatum.package_channel).to eq(params[:package_channel])
      end

      it_behaves_like 'assigns the package creator'
      it_behaves_like 'assigns build to package'
      it_behaves_like 'assigns status to package'
    end

    context 'invalid params' do
      let(:params) do
        {
          package_name: 'my-pkg',
          package_version: '1.0.0',
          package_username: 'foo/bar',
          package_channel: 'stable'
        }
      end

      it 'fails' do
        expect { package }.to raise_exception(ActiveRecord::RecordInvalid)
      end
    end
  end
end
