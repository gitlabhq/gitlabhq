# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::CleanupDependencyProxyWorker, feature_category: :virtual_registry do
  describe '#perform' do
    subject { described_class.new.perform }

    context 'when there are records to be deleted' do
      it_behaves_like 'an idempotent worker' do
        it 'queues the cleanup jobs', :aggregate_failures do
          create(:dependency_proxy_blob, :pending_destruction)
          create(:dependency_proxy_manifest, :pending_destruction)
          create(:virtual_registries_packages_maven_cached_response, :orphan)

          expect(DependencyProxy::CleanupBlobWorker).to receive(:perform_with_capacity).twice
          expect(DependencyProxy::CleanupManifestWorker).to receive(:perform_with_capacity).twice
          expect(::VirtualRegistries::Packages::DestroyOrphanCachedResponsesWorker)
            .to receive(:perform_with_capacity).twice

          subject
        end
      end
    end

    context 'when there are not records to be deleted' do
      it_behaves_like 'an idempotent worker' do
        it 'does not queue the cleanup jobs', :aggregate_failures do
          expect(DependencyProxy::CleanupBlobWorker).not_to receive(:perform_with_capacity)
          expect(DependencyProxy::CleanupManifestWorker).not_to receive(:perform_with_capacity)
          expect(::VirtualRegistries::Packages::DestroyOrphanCachedResponsesWorker)
            .not_to receive(:perform_with_capacity)

          subject
        end
      end
    end
  end
end
