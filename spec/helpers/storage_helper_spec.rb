# frozen_string_literal: true

require "spec_helper"

RSpec.describe StorageHelper, feature_category: :consumables_cost_management do
  describe "#storage_counter" do
    it "formats bytes to one decimal place" do
      expect(helper.storage_counter(1.23.megabytes)).to eq("1.2 MiB")
    end

    it "does not add decimals for sizes < 1 MiB" do
      expect(helper.storage_counter(23.5.kilobytes)).to eq("24 KiB")
    end

    it "does not add decimals for zeroes" do
      expect(helper.storage_counter(2.megabytes)).to eq("2 MiB")
    end

    it "uses commas as thousands separator" do
      if ::Gitlab.next_rails?
        expect(helper.storage_counter(100_000_000_000_000_000_000_000_000)).to eq("84,703.3 ZB")
      else
        expect(helper.storage_counter(100_000_000_000_000_000_000_000)).to eq("86,736.2 EiB")
      end
    end
  end

  describe "#storage_counters_details" do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) do
      create(
        :project,
        namespace: namespace,
        statistics: build(
          :project_statistics,
          namespace: namespace,
          repository_size: 10.kilobytes,
          wiki_size: 10.bytes,
          lfs_objects_size: 20.gigabytes,
          build_artifacts_size: 30.megabytes,
          pipeline_artifacts_size: 11.megabytes,
          snippets_size: 40.megabytes,
          packages_size: 12.megabytes,
          uploads_size: 15.megabytes,
          container_registry_size: 3.gigabytes
        )
      )
    end

    let(:message) do
      'Repository: 10 KiB / Wikis: 10 B / Build Artifacts: 30 MiB / Pipeline Artifacts: 11 MiB / ' \
        'LFS: 20 GiB / Snippets: 40 MiB / Packages: 12 MiB / Uploads: 15 MiB'
    end

    it 'works on ProjectStatistics' do
      expect(helper.storage_counters_details(project.statistics)).to eq(message)
    end

    it 'works on Namespace.with_statistics' do
      namespace_stats = Namespace.with_statistics.find(project.namespace.id)

      expect(helper.storage_counters_details(namespace_stats)).to eq(message)
    end
  end
end
