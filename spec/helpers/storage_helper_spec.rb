require "spec_helper"

describe StorageHelper do
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
    let(:namespace) { create :namespace }
    let(:project) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               repository_size:      10.kilobytes,
                               wiki_size:            10.bytes,
                               lfs_objects_size:     20.gigabytes,
                               build_artifacts_size: 30.megabytes))
    end

    let(:message) { '10 KB repositories, 10 Bytes wikis, 30 MB build artifacts, 20 GB LFS' }

    it 'works on ProjectStatistics' do
      expect(helper.storage_counters_details(project.statistics)).to eq(message)
    end

    it 'works on Namespace.with_statistics' do
      namespace_stats = Namespace.with_statistics.find(project.namespace.id)

      expect(helper.storage_counters_details(namespace_stats)).to eq(message)
    end
  end
end
