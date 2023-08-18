# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::ExtractionWorker, type: :worker, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:package) { create(:rubygems_package, :processing) }

    let(:package_file) { package.package_files.first }
    let(:package_file_id) { package_file.id }
    let(:package_name) { 'TempProject.TempPackage' }
    let(:package_version) { '1.0.0' }
    let(:job_args) { package_file_id }

    subject { described_class.new.perform(*job_args) }

    context 'without errors' do
      let_it_be(:package_for_processing) { create(:rubygems_package, :processing) }
      let(:package_file) { package_for_processing.package_files.first }

      it 'processes the gem', :aggregate_failures do
        expect { subject }
          .to change { Packages::Package.count }.by(0)
          .and change { Packages::PackageFile.count }.by(1)

        expect(Packages::Package.last.id).to be(package_for_processing.id)
        expect(package_for_processing.name).not_to be(package_name)
      end
    end

    shared_examples 'handling error' do |error_message:, error_class:|
      it 'mark the package as errored', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(error_class),
          {
            package_file_id: package_file.id,
            project_id: package.project_id
          }
        )

        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and change { package.reload.status }.from('processing').to('error')

        expect(package.status_message).to match(error_message)
      end
    end

    context 'with controlled errors' do
      context 'handling metadata with invalid size' do
        include_context 'with invalid Rubygems metadata'

        it_behaves_like 'handling error',
          error_class: ::Packages::Rubygems::ProcessGemService::InvalidMetadataError,
          error_message: 'Invalid metadata'
      end

      context 'handling a file error' do
        before do
          package_file.file = nil
        end

        it_behaves_like 'handling error',
          error_class: ::Packages::Rubygems::ProcessGemService::ExtractionError,
          error_message: 'Unable to read gem file'
      end
    end

    context 'with uncontrolled errors' do
      [Zip::Error, StandardError].each do |exception|
        context "handling #{exception}", :aggregate_failures do
          before do
            allow(::Packages::Rubygems::ProcessGemService).to receive(:new).and_raise(exception)
          end

          it_behaves_like 'handling error',
            error_class: exception,
            error_message: "Unexpected error: #{exception}"
        end
      end
    end

    context 'returns when there is no package file' do
      let(:package_file_id) { 999999 }

      it 'returns without action' do
        expect(::Packages::Rubygems::ProcessGemService).not_to receive(:new)

        expect { subject }
          .to change { Packages::Package.count }.by(0)
          .and change { Packages::PackageFile.count }.by(0)
      end
    end
  end
end
