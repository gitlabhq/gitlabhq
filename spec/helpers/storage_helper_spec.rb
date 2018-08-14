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
      if Gitlab.rails5?
        expect(helper.storage_counter(100_000_000_000_000_000_000_000)).to eq("86,736.2 EB")
      else
        expect(helper.storage_counter(100_000_000_000_000_000)).to eq("90,949.5 TB")
      end
    end
  end
end
