# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CarrierWave::Uploader::Url", feature_category: :shared do
  let(:uploader) { MyCoolUploader.new }

  subject(:url) { uploader.url }

  before do
    stub_const("MyCoolUploader", Class.new(CarrierWave::Uploader::Base))
  end

  describe "#url" do
    let(:file) { Class.new.new }

    before do
      allow(uploader).to receive(:file).and_return(file)
    end

    context "when file responds to url" do
      it "returns nil when the file.url is empty" do
        file.define_singleton_method(:url) { nil }

        expect(url).to be_nil
      end

      it "returns the given file url" do
        file.define_singleton_method(:url) { "url" }

        expect(url).to eq("url")
      end

      it "passes any given options to the file url method" do
        file.define_singleton_method(:url) { |x = true| x }
        expect(file).to receive(:url).once.and_call_original

        options = { options: true }
        expect(uploader.url(options)).to eq(options)
      end
    end

    context "when file responds to path" do
      before do
        file.define_singleton_method(:path) { "file/path" }
      end

      context "when the asset host is a string" do
        it "prefix the path with the asset host" do
          expect(uploader).to receive(:asset_host).and_return("host/")

          expect(url).to eq("host/file/path")
        end
      end

      context "when the asset host responds to call" do
        it "prefix the path with the asset host" do
          expect(uploader).to receive(:asset_host).and_return(proc { |f| "callable/#{f.class.class}/" })

          expect(url).to eq("callable/Class/file/path")
        end
      end

      context "when asset_host is empty" do
        context "when base_path is empty" do
          it "returns the file path" do
            expect(url).to eq("file/path")
          end
        end

        context "when base_path is not empty" do
          it "returns the file path prefixed with the base_path" do
            expect(uploader).to receive(:base_path).and_return("base/path/")

            expect(url).to eq("base/path/file/path")
          end
        end
      end
    end

    context "when file does not respond to either url nor path" do
      it "returns nil" do
        expect(url).to eq(nil)
      end
    end
  end
end
