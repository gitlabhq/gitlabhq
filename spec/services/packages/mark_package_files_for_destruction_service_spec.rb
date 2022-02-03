# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackageFilesForDestructionService, :aggregate_failures do
  let(:service) { described_class.new(package_files) }

  describe '#execute', :aggregate_failures do
    subject { service.execute }

    shared_examples 'executing successfully' do
      it 'marks package files for destruction' do
        expect { subject }
          .to change { ::Packages::PackageFile.pending_destruction.count }.by(package_files.size)
      end

      it 'executes successfully' do
        expect(subject).to be_success
        expect(subject.message).to eq('Package files are now pending destruction')
      end
    end

    context 'with no package files' do
      let_it_be(:package_files) { ::Packages::PackageFile.none }

      it_behaves_like 'executing successfully'
    end

    context 'with a single package file' do
      let_it_be(:package_file) { create(:package_file) }
      let_it_be(:package_files) { ::Packages::PackageFile.id_in(package_file.id) }

      it_behaves_like 'executing successfully'
    end

    context 'with many package files' do
      let_it_be(:package_files) { ::Packages::PackageFile.id_in(create_list(:package_file, 3).map(&:id)) }

      it_behaves_like 'executing successfully'
    end

    context 'with an error during the update' do
      let_it_be(:package_files) { ::Packages::PackageFile.none }

      before do
        expect(package_files).to receive(:each_batch).and_raise('error!')
      end

      it 'raises the error' do
        expect { subject }
          .to raise_error('error!')
          .and not_change { ::Packages::PackageFile.pending_destruction.count }
      end
    end
  end
end
