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

  describe 'scopes' do
    describe '.orphan' do
      subject { described_class.orphan }

      let_it_be(:cached_response) { create(:virtual_registries_packages_maven_cached_response) }
      let_it_be(:orphan_cached_response) { create(:virtual_registries_packages_maven_cached_response, :orphan) }

      it { is_expected.to contain_exactly(orphan_cached_response) }
    end

    describe '.pending_destruction' do
      subject { described_class.pending_destruction }

      let_it_be(:cached_response) { create(:virtual_registries_packages_maven_cached_response, :orphan, :processing) }
      let_it_be(:pending_destruction_cached_response) do
        create(:virtual_registries_packages_maven_cached_response, :orphan)
      end

      it { is_expected.to contain_exactly(pending_destruction_cached_response) }
    end
  end

  describe '.next_pending_destruction' do
    subject { described_class.next_pending_destruction }

    let_it_be(:cached_response) { create(:virtual_registries_packages_maven_cached_response) }
    let_it_be(:pending_destruction_cached_response) do
      create(:virtual_registries_packages_maven_cached_response, :orphan)
    end

    it { is_expected.to eq(pending_destruction_cached_response) }
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

  describe '.create_or_update_by!' do
    let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream) }

    let(:size) { 10.bytes }

    subject(:create_or_update) do
      with_threads do
        file = Tempfile.new('test.txt').tap { |f| f.write('test') }
        described_class.create_or_update_by!(
          upstream: upstream,
          group_id: upstream.group_id,
          relative_path: '/test',
          updates: { file: file, size: size }
        )
      ensure
        file.close
        file.unlink
      end
    end

    it 'creates or update the existing record' do
      expect { create_or_update }.to change { described_class.count }.by(1)

      # downloads count don't behave accurately in a race condition situation.
      # That's an accepted tradeoff for now.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/473152 should fix this problem.
      expect(described_class.last.downloads_count).to be_between(2, 5).inclusive
    end

    context 'with invalid updates' do
      let(:size) { nil }

      it 'bubbles up the error' do
        expect { create_or_update }.to not_change { described_class.count }
          .and raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#filename' do
    let(:cached_response) { build(:virtual_registries_packages_maven_cached_response) }

    subject { cached_response.filename }

    it { is_expected.to eq(File.basename(cached_response.relative_path)) }

    context 'when relative_path is nil' do
      before do
        cached_response.relative_path = nil
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#stale?' do
    let(:cached_response) do
      build(:virtual_registries_packages_maven_cached_response, upstream_checked_at: 10.hours.ago)
    end

    let(:threshold) do
      cached_response.upstream_checked_at + cached_response.upstream.registry.cache_validity_hours.hours
    end

    subject { cached_response.stale?(registry: cached_response.upstream.registry) }

    context 'when before the threshold' do
      before do
        allow(Time.zone).to receive(:now).and_return(threshold - 1.hour)
      end

      it { is_expected.to eq(false) }
    end

    context 'when on the threshold' do
      before do
        allow(Time.zone).to receive(:now).and_return(threshold)
      end

      it { is_expected.to eq(false) }
    end

    context 'when after the threshold' do
      before do
        allow(Time.zone).to receive(:now).and_return(threshold + 1.hour)
      end

      it { is_expected.to eq(true) }
    end

    context 'with no registry' do
      before do
        cached_response.upstream.registry = nil
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#bump_statistics', :freeze_time do
    let_it_be_with_reload(:cached_response) { create(:virtual_registries_packages_maven_cached_response) }

    subject(:bump) { cached_response.bump_statistics }

    it 'updates the correct statistics' do
      expect { bump }
        .to change { cached_response.downloaded_at }.to(Time.zone.now)
        .and change { cached_response.downloads_count }.by(1)
    end

    context 'with include_upstream_checked_at' do
      subject(:bump) { cached_response.bump_statistics(include_upstream_checked_at: true) }

      it 'updates the correct statistics' do
        expect { bump }
          .to change { cached_response.reload.downloaded_at }.to(Time.zone.now)
          .and change { cached_response.upstream_checked_at }.to(Time.zone.now)
          .and change { cached_response.downloads_count }.by(1)
      end
    end
  end

  context 'with loose foreign key on virtual_registries_packages_maven_cached_responses.upstream_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:virtual_registries_packages_maven_upstream) }
      let_it_be(:model) { create(:virtual_registries_packages_maven_cached_response, upstream: parent) }
    end
  end

  def with_threads(count: 5, &block)
    return unless block

    # create a race condition - structure from https://blog.arkency.com/2015/09/testing-race-conditions/
    wait_for_it = true

    threads = Array.new(count) do |i|
      Thread.new do
        # A loop to make threads busy until we `join` them
        true while wait_for_it

        yield(i)
      end
    end

    wait_for_it = false
    threads.each(&:join)
  end
end
