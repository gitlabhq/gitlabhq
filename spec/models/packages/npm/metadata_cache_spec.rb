# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::MetadataCache, type: :model, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { '@root/test' }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a Packages::Downloadable }

  describe 'loose foreign keys' do
    it_behaves_like 'update by a loose foreign key' do
      let_it_be(:model) { create(:npm_metadata_cache, status: :default) }

      let!(:parent) { model.project }
    end
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:npm_metadata_caches) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:size) }

    describe '#package_name' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package_name, project: project) }

      it { is_expected.to validate_presence_of(:package_name) }

      describe 'uniqueness' do
        it 'ensures the package name is unique within a given project' do
          expect do
            create(:npm_metadata_cache, package_name: package_name, project: project)
          end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package name has already been taken')
        end

        it 'allows duplicate file names in different projects' do
          expect do
            create(:npm_metadata_cache, package_name: package_name, project: create(:project))
          end.not_to raise_error
        end
      end

      describe 'format' do
        it { is_expected.to allow_value('my.app-11.07.2018').for(:package_name) }
        it { is_expected.to allow_value('@group-1/package').for(:package_name) }
        it { is_expected.to allow_value('@any-scope/package').for(:package_name) }
        it { is_expected.to allow_value('unscoped-package').for(:package_name) }

        it { is_expected.not_to allow_value('my(dom$$$ain)com.my-app').for(:package_name) }
        it { is_expected.not_to allow_value('@inv@lid-scope/package').for(:package_name) }
        it { is_expected.not_to allow_value('@scope/../../package').for(:package_name) }
        it { is_expected.not_to allow_value('@scope%2e%2e%fpackage').for(:package_name) }
        it { is_expected.not_to allow_value('@scope/sub/package').for(:package_name) }
      end
    end
  end

  describe '.find_or_build' do
    subject { described_class.find_or_build(package_name: package_name, project_id: project.id) }

    context 'when a metadata cache exists' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package_name, project: project) }

      it 'finds an existing metadata cache' do
        expect(subject).to eq(npm_metadata_cache)
      end
    end

    context 'when a metadata cache not found' do
      let(:package_name) { 'not_existing' }

      it 'builds a new instance', :aggregate_failures do
        expect(subject).not_to be_persisted
        expect(subject.package_name).to eq(package_name)
        expect(subject.project_id).to eq(project.id)
      end
    end
  end

  describe 'save callbacks' do
    describe 'object_storage_key' do
      let(:object_storage_key) do
        Gitlab::HashedPath.new(
          'packages', 'metadata_caches', 'npm', OpenSSL::Digest::SHA256.hexdigest(package_name),
          root_hash: project.id
        )
      end

      before do
        allow(Gitlab::HashedPath).to receive(:new).and_return(object_storage_key)
      end

      context 'when the record is created' do
        let(:npm_metadata_cache) { build(:npm_metadata_cache, package_name: package_name, project: project) }

        it 'sets object_storage_key' do
          npm_metadata_cache.save!

          expect(npm_metadata_cache.object_storage_key).to eq(object_storage_key.to_s)
        end

        context 'when using `update!`' do
          let(:metadata_content) { {}.to_json }

          it 'sets object_storage_key' do
            npm_metadata_cache.update!(
              file: CarrierWaveStringFile.new(metadata_content),
              size: metadata_content.bytesize
            )

            expect(npm_metadata_cache.object_storage_key).to eq(object_storage_key.to_s)
          end
        end
      end

      context 'when the record is updated' do
        let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package_name, project: project) }

        let(:existing_object_storage_key) { npm_metadata_cache.object_storage_key }
        let(:new_package_name) { 'updated_package_name' }

        it 'does not update object_storage_key' do
          existing_object_storage_key = npm_metadata_cache.object_storage_key

          npm_metadata_cache.update!(package_name: new_package_name)

          expect(npm_metadata_cache.object_storage_key).to eq(existing_object_storage_key)
        end
      end
    end
  end

  describe 'readonly attributes' do
    describe 'object_storage_key' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache) }

      it 'sets object_storage_key' do
        expect(npm_metadata_cache.object_storage_key).to be_present
      end

      context 'when the record is persisted' do
        let(:new_object_storage_key) { 'object/storage/updated_key' }

        it 'does not re-set object_storage_key' do
          npm_metadata_cache.object_storage_key = new_object_storage_key

          npm_metadata_cache.save!

          expect(npm_metadata_cache.object_storage_key).not_to eq(new_object_storage_key)
        end
      end
    end
  end

  describe '.pending_destruction' do
    let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache) }
    let_it_be(:npm_metadata_cache_processing) { create(:npm_metadata_cache, :processing) }
    let_it_be(:npm_metadata_cache_pending_destruction) { create(:npm_metadata_cache, :pending_destruction) }

    subject { described_class.pending_destruction }

    it { is_expected.to contain_exactly(npm_metadata_cache_pending_destruction) }
  end

  describe '.next_pending_destruction' do
    let_it_be(:npm_metadata_cache1) { create(:npm_metadata_cache, created_at: 1.month.ago, updated_at: 1.day.ago) }
    let_it_be(:npm_metadata_cache2) { create(:npm_metadata_cache, created_at: 1.year.ago, updated_at: 1.year.ago) }

    let_it_be(:npm_metadata_cache3) do
      create(:npm_metadata_cache, :pending_destruction, created_at: 2.years.ago, updated_at: 1.month.ago)
    end

    let_it_be(:npm_metadata_cache4) do
      create(:npm_metadata_cache, :pending_destruction, created_at: 3.years.ago, updated_at: 2.weeks.ago)
    end

    it 'returns the oldest pending destruction item based on updated_at' do
      expect(described_class.next_pending_destruction(order_by: :updated_at)).to eq(npm_metadata_cache3)
    end
  end
end
