# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::ProcessPackageFileService, feature_category: :package_registry do
  let(:package_file) { build(:package_file, :cargo) }
  let_it_be(:user_or_deploy_token) { create(:user) }

  let(:service) { described_class.new(package_file, user_or_deploy_token) }

  describe '#execute' do
    subject(:result) { service.execute }

    shared_examples 'raises an error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, error_message) }
    end

    context 'with valid package file' do
      it 'calls the UpdatePackageFromMetadataService' do
        expect_next_instance_of(Packages::Cargo::UpdatePackageFromMetadataService, package_file,
          instance_of(File), user_or_deploy_token) do |service|
          expect(service).to receive(:execute)
        end

        result
      end
    end

    context 'with invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'when linked to a non cargo package' do
      before do
        package_file.package.maven!
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'with a 0 byte package file' do
      before do
        allow_next_instance_of(Packages::PackageFileUploader) do |instance|
          allow(instance).to receive(:size).and_return(0)
        end
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'when package file has no associated package' do
      before do
        allow(package_file).to receive(:package).and_return(nil)
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end
  end
end
