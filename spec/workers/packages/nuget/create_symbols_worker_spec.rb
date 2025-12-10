# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CreateSymbolsWorker, type: :worker, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:package) { create(:nuget_package, without_package_files: true) }
    let_it_be(:package_file) do
      create(
        :package_file,
        :snupkg,
        package: package,
        file_fixture: expand_fixture_path('packages/nuget/package_with_symbols.snupkg')
      )
    end

    subject(:perform) { described_class.new.perform(package_file.id) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [package_file.id] }

      it 'creates a new symbol' do
        expect { perform }.to change { ::Packages::Nuget::Symbol.count }.by(1)
      end
    end

    context 'when errors happened' do
      it 'logs errors', :aggregate_failures do
        expect_next_instance_of(::Packages::Nuget::Symbols::CreateSymbolFilesService) do |service|
          expect(service).to receive(:execute).and_raise(StandardError)
        end

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(StandardError),
          {
            package_file_id: package_file.id,
            project_id: package.project_id
          }
        )

        perform
      end
    end
  end
end
