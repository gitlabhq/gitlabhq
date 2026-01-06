# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ProcessPackageFileService, feature_category: :package_registry do
  # Use `let` instead of `let_it_be` because the "0 byte package file" context
  # mocks `package_file.file`. With `let_it_be`, the same uploader instance is
  # reused across examples, causing the mock to leak to other tests.
  let(:package_file) { create(:package_file, :nuget) }

  let(:service) { described_class.new(package_file) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'raises an error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, error_message) }
    end

    context 'with valid package file' do
      it 'calls the UpdatePackageFromMetadataService' do
        expect_next_instance_of(Packages::Nuget::UpdatePackageFromMetadataService, package_file,
          instance_of(Zip::File), nil) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end

    context 'with invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'when linked to a non nuget package' do
      # Use `let` instead of `let_it_be` to avoid modifying the shared package fixture.
      # The `maven!` call changes the package type, which would persist across tests
      # when using `let_it_be`, causing flaky test failures.
      let(:package_file) { build(:package_file, :nuget, package: build(:maven_package)) }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'with a 0 byte package file' do
      # Use `let` to create package_file AFTER the mock is set up.
      # With `let_it_be`, the uploader instance exists before the `before` block runs,
      # so `allow_next_instance_of` doesn't intercept it.
      let(:package_file) { build(:package_file, :nuget) }

      before do
        allow(package_file.file).to receive(:size).and_return(0)
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end
  end
end
