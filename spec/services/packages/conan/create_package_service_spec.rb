# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Conan::CreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    let(:package) { service_response.payload.fetch(:package) }

    subject(:service_response) { service.execute }

    shared_examples 'returning an error service response and not creating conan package' do |message:|
      it_behaves_like 'returning an error service response', message: message
      it { is_expected.to have_attributes(reason: :record_invalid) }

      it 'does not create a conan package' do
        expect { service_response }
        .to not_change { Packages::Package.conan.count }
        .and not_change { Packages::PackageFile.count }
      end
    end

    context 'valid params' do
      let(:params) do
        {
          package_name: 'my-pkg',
          package_version: '1.0.0',
          package_username: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path),
          package_channel: 'stable'
        }
      end

      it_behaves_like 'returning a success service response'

      it 'creates a new package' do
        expect(package).to be_valid
        expect(package.name).to eq(params[:package_name])
        expect(package.version).to eq(params[:package_version])
        expect(package.package_type).to eq('conan')
        expect(package.conan_metadatum.package_username).to eq(params[:package_username])
        expect(package.conan_metadatum.package_channel).to eq(params[:package_channel])
      end

      it_behaves_like 'assigns the package creator'

      it_behaves_like 'assigns build to package' do
        subject { super().payload.fetch(:package) }
      end

      it_behaves_like 'assigns status to package' do
        subject { super().payload.fetch(:package) }
      end
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

      it_behaves_like 'returning an error service response and not creating conan package',
        message: 'Validation failed: Conan metadatum package username is invalid'
    end

    context 'with existing recipe' do
      let_it_be(:existing_package) { create(:conan_package, project: project) }

      let(:params) do
        {
          package_name: existing_package.name,
          package_version: existing_package.version,
          package_username: existing_package.conan_metadatum.package_username,
          package_channel: existing_package.conan_metadatum.package_channel
        }
      end

      it_behaves_like 'returning an error service response and not creating conan package',
        message: 'Validation failed: Package recipe already exists'
    end
  end
end
