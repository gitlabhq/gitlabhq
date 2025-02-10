# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Maven::Package, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to have_one(:maven_metadatum).inverse_of(:package) }
  end

  describe 'nested attributes' do
    it { is_expected.to accept_nested_attributes_for(:maven_metadatum) }
  end

  describe 'validations' do
    describe '#version' do
      it 'allows accepted values' do
        is_expected.to allow_values('0', '1', '10', '1.0', '1.3.350.v20200505-1744', '1.1-beta-2',
          '1.2-SNAPSHOT', '12.1.2-2-1', '1.2.3-beta', '10.2.3-beta', '2.0.0.v200706041905-7C78EK9E_EkMNfNOd2d8qq',
          '1.2-alpha-1-20050205.060708-1', '703220b4e2cea9592caeb9f3013f6b1e5335c293', 'RELEASE').for(:version)
      end

      it 'does not allow unaccepted values' do
        is_expected.not_to allow_values('..1.2.3', '1.2.3..beta', '  1.2.3', "1.2.3  \r\t", "\r\t 1.2.3",
          '1.2.3-4/../../', '1.2.3-4%2e%2e%', '../../../../../1.2.3', '%2e%2e%2f1.2.3').for(:version)
      end
    end
  end

  describe '.only_maven_packages_with_path' do
    let_it_be(:package_one) { create(:maven_package) }
    let_it_be(:package_two) { create(:maven_package) }

    let(:path) { "#{package_two.name}/#{package_two.version}" }

    subject { described_class.only_maven_packages_with_path(path) }

    it { is_expected.to contain_exactly(package_two) }

    context 'with CTE' do
      let(:use_cte) { true }

      subject { described_class.only_maven_packages_with_path(path, use_cte: use_cte) }

      it { is_expected.to contain_exactly(package_two) }
    end
  end

  describe '#sync_maven_metadata' do
    let_it_be(:user) { create(:user) }
    let_it_be(:package) { create(:maven_package) }

    subject(:sync_maven_metadata) { package.sync_maven_metadata(user) }

    shared_examples 'not enqueuing a sync worker job' do
      it 'does not enqueue a sync worker job' do
        expect(::Packages::Maven::Metadata::SyncWorker)
          .not_to receive(:perform_async)

        sync_maven_metadata
      end
    end

    it 'enqueues a sync worker job' do
      expect(::Packages::Maven::Metadata::SyncWorker)
        .to receive(:perform_async).with(user.id, package.project.id, package.name)

      sync_maven_metadata
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'not enqueuing a sync worker job'
    end

    context 'with a versionless maven package' do
      let_it_be(:package) { create(:maven_package, version: nil) }

      it_behaves_like 'not enqueuing a sync worker job'
    end
  end

  describe '#prevent_concurrent_inserts' do
    let(:maven_package) { build(:maven_package, project_id: 5) }
    let(:lock_key) do
      maven_package.connection.quote(
        "#{described_class.table_name}-#{maven_package.project_id}-#{maven_package.name}-#{maven_package.version}"
      )
    end

    subject(:exec) { maven_package.send(:prevent_concurrent_inserts) }

    it 'executes advisory lock' do
      expect(maven_package.connection).to receive(:execute).with("SELECT pg_advisory_xact_lock(hashtext(#{lock_key}))")

      exec
    end
  end
end
