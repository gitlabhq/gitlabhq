# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::MetadataCache, type: :model, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { '@root/test' }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a Packages::Downloadable }

  it_behaves_like 'destructible', factory: :npm_metadata_cache

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

  describe '#object_storage_key' do
    it_behaves_like 'object_storage_key callbacks' do
      let(:model) { build(:npm_metadata_cache, project: project, package_name: package_name) }
      let(:expected_object_storage_key) do
        Gitlab::HashedPath.new(
          'packages', 'metadata_caches', 'npm', OpenSSL::Digest::SHA256.hexdigest(package_name),
          root_hash: project.id
        )
      end
    end

    it_behaves_like 'object_storage_key readonly attributes' do
      let_it_be(:model) { create(:npm_metadata_cache, project: project, package_name: package_name) }
    end
  end
end
