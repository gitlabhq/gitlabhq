# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::ErrorHandling, feature_category: :package_registry do
  let_it_be(:worker_class) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
      include ::Packages::ErrorHandling
    end
  end

  let_it_be_with_reload(:package) { create(:generic_package, :processing, :with_zip_file) }

  let(:package_file) { package.package_files.first }
  let(:worker) { worker_class.new }

  shared_examples 'updates the package status and status message' do
    it :aggregate_failures do
      expect { subject }
        .to change { package.status }.to('error')
        .and change { package.status_message }.to(error_message)
    end
  end

  shared_examples 'truncating the error message' do
    it 'truncates the error message' do
      subject

      expect(package.status_message.length).to eq(::Packages::Package::STATUS_MESSAGE_MAX_LENGTH)
    end
  end

  describe '#process_package_file_error' do
    let(:package_name) { 'TempProject.TempPackage' }
    let(:exception) { StandardError.new('42') }
    let(:extra_log_payload) { { answer: 42 } }
    let(:expected_log_payload) do
      {
        project_id: package_file.project_id,
        package_file_id: package_file.id,
        answer: 42
      }
    end

    subject do
      worker.process_package_file_error(
        package_file: package_file,
        exception: exception,
        extra_log_payload: extra_log_payload
      )
    end

    it 'logs the error with the correct parameters' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(exception, expected_log_payload)

      subject
    end

    described_class::CONTROLLED_ERRORS.each do |exception_class|
      context "with controlled exception #{exception_class}" do
        let(:exception) { exception_class.new }

        it_behaves_like 'updates the package status and status message' do
          let(:error_message) { exception.message }
        end
      end
    end

    context 'with all other errors' do
      let(:exception) { StandardError.new('String that will not appear in status_message') }

      it_behaves_like 'updates the package status and status message' do
        let(:error_message) { 'Unexpected error: StandardError' }
      end
    end

    context 'with a very long error message' do
      let(:exception) { ArgumentError.new('a' * 1000) }

      it_behaves_like 'truncating the error message'
    end
  end

  describe '#process_package_error_service_response' do
    subject do
      worker.process_package_error_service_response(package_file: package_file, message: error_message)
    end

    it_behaves_like 'updates the package status and status message' do
      let(:error_message) { 'Attachment data is empty.' }
    end

    context 'with a very long error message' do
      let(:error_message) { 'a' * 1000 }

      it_behaves_like 'truncating the error message'
    end
  end
end
