# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Cache, :use_clean_rails_memory_store_caching do
  let_it_be(:project1) { build_stubbed(:project) }
  let_it_be(:project2) { build_stubbed(:project) }

  let(:project1_key1) { "#{project1.id}_key1" }
  let(:project1_key2) { "#{project1.id}_key2" }
  let(:project2_key1) { "#{project2.id}_key1" }

  let(:cache1) { described_class.for(project1) }
  let(:cache2) { described_class.for(project2) }

  before do
    cache1.fetch(project1_key1) { 'data1' }
    cache1.fetch(project1_key2) { 'data2' }
    cache2.fetch(project2_key1) { 'data3' }
  end

  describe '.fetch' do
    it 'stores data correctly' do
      described_class.fetch('key1') { 'data1' }
      described_class.fetch('key2') { 'data2' }

      expect(described_class.fetch('key1')).to eq('data1')
      expect(described_class.fetch('key2')).to eq('data2')
    end
  end

  describe '.for' do
    it 'returns a new instance' do
      expect(described_class.for(project1)).to be_instance_of(described_class)
    end
  end

  describe '#fetch' do
    it 'stores data correctly' do
      expect(cache1.fetch(project1_key1)).to eq('data1')
      expect(cache1.fetch(project1_key2)).to eq('data2')
      expect(cache2.fetch(project2_key1)).to eq('data3')
    end
  end

  describe '#delete_all!' do
    it 'deletes keys of the given project', :aggregate_failures do
      cache1.delete_all!

      expect(Rails.cache.exist?(project1_key1)).to be(false)
      expect(Rails.cache.exist?(project1_key2)).to be(false)
      expect(cache2.fetch(project2_key1)).to eq('data3')

      cache2.delete_all!

      expect(Rails.cache.exist?(project2_key1)).to be(false)
    end

    it 'does not fail when nothing to delete' do
      project3 = build_stubbed(:project)
      cache3 = described_class.for(project3)

      expect { cache3.delete_all! }.not_to raise_error
    end
  end

  context 'multiple fetches and deletes' do
    specify :aggregate_failures do
      cache1.delete_all!

      expect(Rails.cache.exist?(project1_key1)).to be(false)
      expect(Rails.cache.exist?(project1_key2)).to be(false)

      cache1.fetch("#{project1.id}_key3") { 'data1' }
      cache1.fetch("#{project1.id}_key4") { 'data2' }

      expect(cache1.fetch("#{project1.id}_key3")).to eq('data1')
      expect(cache1.fetch("#{project1.id}_key4")).to eq('data2')

      cache1.delete_all!

      expect(Rails.cache.exist?("#{project1.id}_key3")).to be(false)
      expect(Rails.cache.exist?("#{project1.id}_key4")).to be(false)
    end
  end
end
