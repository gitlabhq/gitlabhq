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
    Gitlab::Webpack::Manifest.clear_manifest!

    example.run

    Gitlab::Webpack::Manifest.clear_manifest!
  end

  shared_examples_for "a valid manifest" do
    it "returns single entry asset paths from the manifest" do
      expect(Gitlab::Webpack::Manifest.asset_paths("entry2")).to eq(["/public_path/entry2.js"])
    end

    it "returns multiple entry asset paths from the manifest" do
      expect(Gitlab::Webpack::Manifest.asset_paths("entry1")).to eq(["/public_path/entry1.js", "/public_path/entry1-a.js"])
    end

    it "errors on a missing entry point" do
      expect { Gitlab::Webpack::Manifest.asset_paths("herp") }.to raise_error(Gitlab::Webpack::Manifest::AssetMissingError)
    end
  end

  before do
    # Test that config variables work while we're here
    ::Rails.configuration.webpack.dev_server.host = 'hostname'
    ::Rails.configuration.webpack.dev_server.port = 1999
    ::Rails.configuration.webpack.dev_server.manifest_host = 'hostname'
    ::Rails.configuration.webpack.dev_server.manifest_port = 2000
    ::Rails.configuration.webpack.manifest_filename = "my_manifest.json"
    ::Rails.configuration.webpack.public_path = "public_path"
    ::Rails.configuration.webpack.output_dir = "manifest_output"
  end

  context "with dev server enabled" do
    before do
      ::Rails.configuration.webpack.dev_server.enabled = true

      stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: manifest, status: 200)
    end

    describe ".asset_paths" do
      it_behaves_like "a valid manifest"

      it "errors if we can't find the manifest" do
        ::Rails.configuration.webpack.manifest_filename = "broken.json"
        stub_request(:get, "http://hostname:2000/public_path/broken.json").to_raise(SocketError)

        expect { Gitlab::Webpack::Manifest.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError)
      end

      describe "webpack errors" do
        context "when webpack has 'Module build failed' errors in its manifest" do
          it "errors" do
            error_manifest = Gitlab::Json.parse(manifest).merge("errors" => [
              "somethingModule build failed something",
              "I am an error"
            ]).to_json
            stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)

            expect { Gitlab::Webpack::Manifest.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::WebpackError)
          end
        end

        context "when webpack does not have 'Module build failed' errors in its manifest" do
          it "does not error" do
            error_manifest = Gitlab::Json.parse(manifest).merge("errors" => ["something went wrong"]).to_json
            stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)

            expect { Gitlab::Webpack::Manifest.asset_paths("entry1") }.not_to raise_error
          end
        end

        it "does not error if errors is present but empty" do
          error_manifest = Gitlab::Json.parse(manifest).merge("errors" => []).to_json
          stub_request(:get, "http://hostname:2000/public_path/my_manifest.json").to_return(body: error_manifest, status: 200)
          expect { Gitlab::Webpack::Manifest.asset_paths("entry1") }.not_to raise_error
        end
      end
    end
  end

  context "with dev server disabled" do
    before do
      ::Rails.configuration.webpack.dev_server.enabled = false
      allow(File).to receive(:read).with(::Rails.root.join("manifest_output/my_manifest.json")).and_return(manifest)
    end

    describe ".asset_paths" do
      it_behaves_like "a valid manifest"

      it "errors if we can't find the manifest" do
        ::Rails.configuration.webpack.manifest_filename = "broken.json"
        allow(File).to receive(:read).with(::Rails.root.join("manifest_output/broken.json")).and_raise(Errno::ENOENT)
        expect { Gitlab::Webpack::Manifest.asset_paths("entry1") }.to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError)
      end
    end
  end
end
