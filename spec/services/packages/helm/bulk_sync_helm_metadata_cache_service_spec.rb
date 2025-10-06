# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::BulkSyncHelmMetadataCacheService, :clean_gitlab_redis_shared_state, feature_category: :package_registry do
  let_it_be_with_reload(:metadata) { [metadatum1, metadatum2] }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:channel1) { 'alpha' }
  let_it_be(:channel2) { 'beta' }
  let_it_be(:metadatum1) { create(:helm_file_metadatum, channel: channel1, project: project) }
  let_it_be(:metadatum2) { create(:helm_file_metadatum, channel: channel2, project: project) }
  let(:package_files) { Packages::PackageFile.id_in([metadatum1.package_file_id, metadatum2.package_file_id]) }
  let(:service) { described_class.new(user, package_files) }

  describe '#execute' do
    subject(:execute) { service.execute }

    before do
      allow(Packages::Helm::CreateMetadataCacheWorker).to receive(:bulk_perform_async_with_contexts)
    end

    it 'returns success response' do
      expect(execute).to be_success
    end

    it 'enqueues bulk perform job', :aggregate_failures do
      execute

      expect(::Packages::Helm::CreateMetadataCacheWorker)
        .to have_received(:bulk_perform_async_with_contexts) do |metadata, arguments_proc:, context_proc:|
          expect(metadata.map(&:channel)).to match_array([channel1, channel2])

          metadata.each do |metadatum|
            expect(arguments_proc.call(metadatum)).to eq([metadatum.project_id, metadatum.channel])
            expect(context_proc.call(metadatum)).to eq(project: metadatum.project, user: user)
          end
        end
    end

    context 'when Packages::Helm::FileMetadatum is not found' do
      before do
        Packages::Helm::FileMetadatum.delete_all
      end

      it 'returns success response' do
        expect(execute).to be_success
      end

      it 'does nothing' do
        expect(::Packages::Helm::CreateMetadataCacheWorker).not_to have_received(:bulk_perform_async_with_contexts)
      end
    end
  end
end
