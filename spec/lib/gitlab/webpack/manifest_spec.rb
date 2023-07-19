# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Gitlab::Webpack::Manifest do
  let(:manifest) do
    <<-EOF
      {
        "errors": [],
        "assetsByChunkName": {
          "entry1": [ "entry1.js", "entry1-a.js" ],
          "entry2": "entry2.js"
        }
      }
    EOF
  end

  around do |example|
    described_class.clear_manifest!

    example.run

    described_class.clear_manifest!
  end

  shared_examples_for "a valid manifest" do
    it "returns single entry asset paths from the manifest" do
      expect(described_class.asset_paths("entry2")).to eq(["/public_path/entry2.js"])
    end

    it "returns multiple entry asset paths from the manifest" do
      expect(described_class.asset_paths("entry1")).to eq(["/public_path/entry1.js", "/public_path/entry1-a.js"])
    end

    it "errors on a missing entry point" do
      expect { described_class.asset_paths("herp") }.to raise_error(Gitlab::Webpack::Manifest::AssetMissingError)
    end
  end

  before do
    # Test that config variables work while we're here
    allow(Gitlab.config.webpack.dev_server).to receive_messages(host: 'hostname', port: 2000, https: false)
    allow(Gitlab.config.webpack).to receive(:manifest_filename).and_return('my_manifest.json')
    allow(Gitlab.config.webpack).to receive(:public_path).and_return('public_path')
    allow(Gitlab.config.webpack).to receive(:output_dir).and_return('manifest_output')
  end

  context "with dev server enabled" do
    before do
      allow(Gitlab.config.webpack.dev_server).to receive(:enabled).and_return(true)

      stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: manifest, status: 200)
    end

    describe ".asset_paths" do
      it_behaves_like "a valid manifest"

      it "errors if we can't find the manifest" do
        allow(Gitlab.config.webpack).to receive(:manifest_filename).and_return('broken.json')
        stub_request(:get, "http://hostname:2000/public_path/broken.json").to_raise(SocketError)

        expect { described_class.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError)
      end

      describe "webpack errors" do
        context "when webpack has 'Module build failed' errors in its manifest" do
          it "errors" do
            error_manifest = Gitlab::Json.parse(manifest).merge("errors" =>
              [
                "somethingModule build failed something",
                "I am an error"
              ]).to_json
            stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)

            expect { described_class.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::WebpackError)
          end
        end

        context "when webpack does not have 'Module build failed' errors in its manifest" do
          it "does not error" do
            error_manifest = Gitlab::Json.parse(manifest).merge("errors" => ["something went wrong"]).to_json
            stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)

            expect { described_class.asset_paths("entry1") }.not_to raise_error
          end
        end

        it "does not error if errors is present but empty" do
          error_manifest = Gitlab::Json.parse(manifest).merge("errors" => []).to_json
          stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)
          expect { described_class.asset_paths("entry1") }.not_to raise_error
        end
      end
    end
  end

  context "with dev server disabled" do
    before do
      allow(Gitlab.config.webpack.dev_server).to receive(:enabled).and_return(false)
      stub_file_read(::Rails.root.join("manifest_output/my_manifest.json"), content: manifest)
    end

    describe ".asset_paths" do
      it_behaves_like "a valid manifest"

      it "errors if we can't find the manifest" do
        allow(Gitlab.config.webpack).to receive(:manifest_filename).and_return('broken.json')
        stub_file_read(::Rails.root.join("manifest_output/broken.json"), error: Errno::ENOENT)
        expect { described_class.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError)
      end
    end
  end
end
