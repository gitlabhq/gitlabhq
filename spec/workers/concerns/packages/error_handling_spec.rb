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

  let(:worker) { worker_class.new }

  describe '#process_package_file_error' do
    let_it_be_with_reload(:package) { create(:generic_package, :processing, :with_zip_file) }

    let(:package_file) { package.package_files.first }
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

    shared_examples 'updates the package status and status message' do |error_message:|
      it :aggregate_failures do
        expect { subject }
          .to change { package.status }.to('error')
          .and change { package.status_message }.to(error_message)
      end
    end

    described_class::CONTROLLED_ERRORS.each do |exception_class|
      context "with controlled exception #{exception_class}" do
        let(:exception) { exception_class.new }

        it_behaves_like 'updates the package status and status message', error_message: exception_class.new.message
      end
    end

    context 'with all other errors' do
      let(:exception) { StandardError.new('String that will not appear in status_message') }

      it_behaves_like 'updates the package status and status message',
        error_message: 'Unexpected error: StandardError'
    end

    context 'with a very long error message' do
      let(:exception) { ArgumentError.new('a' * 1000) }

      it 'truncates the error message' do
        subject

        expect(package.status_message.length).to eq(::Packages::Package::STATUS_MESSAGE_MAX_LENGTH)
      end
    end
  end
end
