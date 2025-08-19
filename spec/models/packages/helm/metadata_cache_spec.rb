# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::MetadataCache, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:channel) { 'release' }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a Packages::Downloadable }

  it_behaves_like 'destructible', factory: :helm_metadata_cache

  describe 'loose foreign keys' do
    it_behaves_like 'update by a loose foreign key' do
      let_it_be(:model) { create(:helm_metadata_cache, status: :default) }

      let!(:parent) { model.project }
    end
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:helm_metadata_caches) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:channel) }
    it { is_expected.to validate_presence_of(:object_storage_key) }

    describe 'uniqueness' do
      let_it_be(:helm_metadata_cache) { create(:helm_metadata_cache, project: project, channel: channel) }

      it 'ensures the channel is unique with the given project' do
        expect do
          create(:helm_metadata_cache, project: project, channel: channel)
        end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Channel has already been taken')
      end

      it 'allows duplicate channel in different projects' do
        expect do
          create(:helm_metadata_cache, project: create(:project), channel: channel)
        end.not_to raise_error
      end
    end

    describe '#channel' do
      describe 'format' do
        it { is_expected.to allow_value('a' * 255).for(:channel) }
        it { is_expected.to allow_value('release').for(:channel) }
        it { is_expected.to allow_value('my-repo').for(:channel) }
        it { is_expected.to allow_value('my-repo42').for(:channel) }

        it { is_expected.not_to allow_value('a' * 256).for(:channel) }
        it { is_expected.not_to allow_value('').for(:channel) }
        it { is_expected.not_to allow_value('hé').for(:channel) }
      end
    end
  end

  describe '#object_storage_key' do
    it_behaves_like 'object_storage_key callbacks' do
      let(:model) { build(:helm_metadata_cache, project: project, channel: channel) }
      let(:expected_object_storage_key) do
        Gitlab::HashedPath.new(
          'packages', 'helm', 'metadata_caches', OpenSSL::Digest::SHA256.hexdigest(channel),
          root_hash: project.id
        )
      end
    end

    it_behaves_like 'object_storage_key readonly attributes' do
      let_it_be(:model) { create(:helm_metadata_cache, project: project, channel: channel) }
    end
  end

  describe '.find_or_build' do
    subject(:helm_metadata_cache) { described_class.find_or_build(project_id: project.id, channel: channel) }

    context 'when a metadata cache exists' do
      let_it_be(:existed_helm_metadata_cache) { create(:helm_metadata_cache, project: project, channel: channel) }

      it 'finds an existing metadata cache' do
        expect(helm_metadata_cache).to eq(existed_helm_metadata_cache)
      end
    end

    context 'when a metadata cache not found' do
      let(:channel) { 'not_existing' }

      it 'builds a new instance', :aggregate_failures do
        expect(helm_metadata_cache).not_to be_persisted
        expect(helm_metadata_cache.channel).to eq(channel)
        expect(helm_metadata_cache.project_id).to eq(project.id)
      end
    end
  end
end
