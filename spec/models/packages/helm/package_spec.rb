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

    describe '#sync_helm_metadata_cache' do
      let_it_be(:package) { create(:helm_package, without_package_files: true) }
      let_it_be(:channel) { 'stable' }
      let_it_be(:package_file) { create(:helm_package_file, package: package, channel: channel) }

      it 'enqueues a sync worker job' do
        expect(::Packages::Helm::CreateMetadataCacheWorker)
          .to receive(:perform_async).with(package.project_id, channel)

        package.reload
        package.sync_helm_metadata_cache
      end
    end
  end
end
