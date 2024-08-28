# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::CachedResponse, type: :model, feature_category: :virtual_registry do
  subject(:cached_response) { build(:virtual_registries_packages_maven_cached_response) }

  it { is_expected.to include_module(FileStoreMounter) }

  describe 'validations' do
    %i[group file relative_path content_type downloads_count size].each do |attr|
      it { is_expected.to validate_presence_of(attr) }
    end

    %i[relative_path upstream_etag content_type].each do |attr|
      it { is_expected.to validate_length_of(attr).is_at_most(255) }
    end
    it { is_expected.to validate_numericality_of(:downloads_count).only_integer.is_greater_than(0) }

    context 'with persisted cached response' do
      before do
        cached_response.save!
      end

      it { is_expected.to validate_uniqueness_of(:relative_path).scoped_to(:upstream_id) }

      context 'when upstream_id is nil' do
        let(:new_cached_response) { build(:virtual_registries_packages_maven_cached_response) }

        before do
          cached_response.update!(upstream_id: nil)
          new_cached_response.upstream = nil
        end

        it 'does not validate uniqueness of relative_path' do
          new_cached_response.validate
          expect(new_cached_response.errors.messages_for(:relative_path)).not_to include 'has already been taken'
        end
      end
    end
  end

  describe 'associations' do
    it do
      is_expected.to belong_to(:upstream)
        .class_name('VirtualRegistries::Packages::Maven::Upstream')
        .inverse_of(:cached_responses)
    end
  end

  describe 'object storage key' do
    it 'can not be null' do
      cached_response.object_storage_key = nil
      cached_response.relative_path = nil

      expect(cached_response).to be_invalid
      expect(cached_response.errors.full_messages).to include("Object storage key can't be blank")
    end

    it 'can not be too large' do
      cached_response.object_storage_key = 'a' * 256
      cached_response.relative_path = nil

      expect(cached_response).to be_invalid
      expect(cached_response.errors.full_messages)
        .to include('Object storage key is too long (maximum is 255 characters)')
    end

    it 'is set before saving' do
      expect { cached_response.save! }
        .to change { cached_response.object_storage_key }.from(nil).to(an_instance_of(String))
    end

    context 'with a persisted cached response' do
      let(:key) { cached_response.object_storage_key }

      before do
        cached_response.save!
      end

      it 'does not change after an update' do
        expect(key).to be_present

        cached_response.update!(
          file: CarrierWaveStringFile.new('test'),
          size: 2.kilobytes
        )

        expect(cached_response.object_storage_key).to eq(key)
      end

      it 'is read only' do
        expect(key).to be_present

        cached_response.object_storage_key = 'new-key'
        cached_response.save!

        expect(cached_response.reload.object_storage_key).to eq(key)
      end
    end
  end

  describe '.search_by_relative_path' do
    let_it_be(:cached_response) { create(:virtual_registries_packages_maven_cached_response) }
    let_it_be(:other_cached_response) do
      create(:virtual_registries_packages_maven_cached_response, relative_path: 'other/path')
    end

    subject { described_class.search_by_relative_path(relative_path) }

    context 'with a matching relative path' do
      let(:relative_path) { cached_response.relative_path.slice(3, 8) }

      it { is_expected.to contain_exactly(cached_response) }
    end
  end
end
