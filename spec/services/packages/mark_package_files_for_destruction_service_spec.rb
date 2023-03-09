# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackageFilesForDestructionService, :aggregate_failures,
  feature_category: :package_registry do
  let(:service) { described_class.new(package_files) }

  describe '#execute', :aggregate_failures do
    let(:batch_deadline) { nil }

    subject { service.execute(batch_deadline: batch_deadline) }

    shared_examples 'executing successfully' do |marked_package_files_count: 0|
      it 'marks package files for destruction' do
        expect { subject }
          .to change { ::Packages::PackageFile.pending_destruction.count }.by(package_files.size)
      end

      it 'executes successfully' do
        expect(subject).to be_success
        expect(subject.message).to eq('Package files are now pending destruction')
        expect(subject.payload).to eq(marked_package_files_count: marked_package_files_count)
      end
    end

    context 'with no package files' do
      let_it_be(:package_files) { ::Packages::PackageFile.none }

      it_behaves_like 'executing successfully'
    end

    context 'with a single package file' do
      let_it_be(:package_file) { create(:package_file) }
      let_it_be(:package_files) { ::Packages::PackageFile.id_in(package_file.id) }

      it_behaves_like 'executing successfully', marked_package_files_count: 1
    end

    context 'with many package files' do
      let_it_be(:package_files) { ::Packages::PackageFile.id_in(create_list(:package_file, 3).map(&:id)) }

      it_behaves_like 'executing successfully', marked_package_files_count: 3

      context 'with a batch deadline' do
        let_it_be(:batch_deadline) { 250.seconds.from_now }

        context 'when the deadline is not hit' do
          before do
            expect(Time.zone).to receive(:now).and_return(batch_deadline - 10.seconds)
          end

          it_behaves_like 'executing successfully', marked_package_files_count: 3
        end

        context 'when the deadline is hit' do
          it 'does not execute the batch loop' do
            expect(Time.zone).to receive(:now).and_return(batch_deadline + 10.seconds)
            expect { subject }.to not_change { ::Packages::PackageFile.pending_destruction.count }
            expect(subject).to be_error
            expect(subject.message).to eq('Timeout while marking package files as pending destruction')
            expect(subject.payload).to eq(marked_package_files_count: 0)
          end
        end
      end

      context 'when a batch size is defined' do
        let_it_be(:batch_deadline) { 250.seconds.from_now }

        let(:batch_size) { 2 }

        subject { service.execute(batch_deadline: batch_deadline, batch_size: batch_size) }

        before do
          expect(Time.zone).to receive(:now).twice.and_call_original
        end

        it_behaves_like 'executing successfully', marked_package_files_count: 3
      end
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
