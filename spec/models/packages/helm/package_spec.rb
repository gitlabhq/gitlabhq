# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::Package, type: :model, feature_category: :package_registry do
  describe 'validations' do
    describe '#name' do
      it { is_expected.to allow_value('prometheus').for(:name) }
      it { is_expected.to allow_value('rook-ceph').for(:name) }
      it { is_expected.not_to allow_value('a+b').for(:name) }
      it { is_expected.not_to allow_value('Hé').for(:name) }
    end

    describe '#version' do
      it { is_expected.not_to allow_value(nil).for(:version) }
      it { is_expected.not_to allow_value('').for(:version) }
      it { is_expected.to allow_value('v1.2.3').for(:version) }
      it { is_expected.to allow_value('1.2.3').for(:version) }
      it { is_expected.not_to allow_value('v1.2').for(:version) }
    end

    describe '#sync_helm_metadata_caches' do
      subject(:sync) { package.sync_helm_metadata_caches(user) }

      let_it_be_with_reload(:package) { create(:helm_package, without_package_files: true) }
      let_it_be(:channel) { 'stable' }
      let_it_be(:package_file) { create(:helm_package_file, package: package, channel: channel) }
      let(:user) { package.creator }
      let(:helm_file_metadatum) { package_file.helm_file_metadatum }

      before do
        allow(Packages::Helm::CreateMetadataCacheWorker).to receive(:bulk_perform_async_with_contexts)
      end

      shared_examples 'enqueue worker job' do
        it 'enqueues a sync worker job', :aggregate_failures do
          sync

          expect(::Packages::Helm::CreateMetadataCacheWorker)
            .to have_received(:bulk_perform_async_with_contexts) do |metadata, arguments_proc:, context_proc:|
              expect(metadata.map(&:channel)).to match_array(channels)

              expect(arguments_proc.call(helm_file_metadatum)).to eq([package.project_id, helm_file_metadatum.channel])
              expect(context_proc.call(channel)).to eq(project: package.project, user: user)
            end
        end
      end

      shared_examples 'does nothing' do
        it 'does not enqueue a sync worker job' do
          expect(::Packages::Helm::CreateMetadataCacheWorker).not_to receive(:bulk_perform_async_with_contexts)

          sync
        end
      end

      it_behaves_like 'enqueue worker job' do
        let(:channels) { [channel] }
      end

      context 'when package does not have any package files' do
        before do
          package.package_files.delete_all
        end

        it_behaves_like 'does nothing'
      end

      context 'when package has package file without helm_metadatum' do
        before do
          package_file.helm_file_metadatum.delete
        end

        it_behaves_like 'does nothing'
      end

      context 'when package has multiple package files' do
        context 'without duplicated channels' do
          let_it_be(:channel2) { 'rc' }
          let_it_be(:package_file2) { create(:helm_package_file, package: package, channel: channel2) }

          it_behaves_like 'enqueue worker job' do
            let(:channels) { [channel, channel2] }
          end
        end

        context 'with duplicated channels', :aggregate_failures do
          let_it_be(:package_file2) { create(:helm_package_file, package: package, channel: channel) }

          it_behaves_like 'enqueue worker job' do
            let(:channels) { [channel] }
          end
        end
      end
    end
  end
end
