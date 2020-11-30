# frozen_string_literal: true

require "spec_helper"

RSpec.describe StorageHelper do
  describe "#storage_counter" do
    it "formats bytes to one decimal place" do
      expect(helper.storage_counter(1.23.megabytes)).to eq("1.2 MB")
    end

    it "does not add decimals for sizes < 1 MB" do
      expect(helper.storage_counter(23.5.kilobytes)).to eq("24 KB")
    end

    it "does not add decimals for zeroes" do
      expect(helper.storage_counter(2.megabytes)).to eq("2 MB")
    end

    it "uses commas as thousands separator" do
      expect(helper.storage_counter(100_000_000_000_000_000_000_000)).to eq("86,736.2 EB")
    end
  end

  describe "#storage_counters_details" do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               namespace:            namespace,
                               repository_size:      10.kilobytes,
                               wiki_size:            10.bytes,
                               lfs_objects_size:     20.gigabytes,
                               build_artifacts_size: 30.megabytes,
                               snippets_size:        40.megabytes,
                               packages_size:        12.megabytes,
                               uploads_size:         15.megabytes))
    end

    let(:message) { 'Repository: 10 KB / Wikis: 10 Bytes / Build Artifacts: 30 MB / LFS: 20 GB / Snippets: 40 MB / Packages: 12 MB / Uploads: 15 MB' }

    it 'works on ProjectStatistics' do
      expect(helper.storage_counters_details(project.statistics)).to eq(message)
    end

    it 'works on Namespace.with_statistics' do
      namespace_stats = Namespace.with_statistics.find(project.namespace.id)

      expect(helper.storage_counters_details(namespace_stats)).to eq(message)
    end
  end
end
