# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Gitlab::Webpack::Manifest, feature_category: :tooling do
  let(:manifest) do
    <<-JSON
      {
        "errors": [],
        "assetsByChunkName": {
          "entry1": [ "entry1.js", "entry1-a.js" ],
          "entry2": "entry2.js"
        }
      }
    JSON
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

    describe "dev server errors" do
      let(:original_error) { Errno::ECONNREFUSED.new("connect(2)") }

      before do
        allow(Gitlab::Webpack::FileLoader).to receive(:load).and_raise(
          Gitlab::Webpack::FileLoader::DevServerLoadError.new("http://localhost:3808/manifest", original_error)
        )
      end

      it "names the rspack service when the rspack manifest is requested" do
        expect { described_class.asset_paths("entry1", manifest_filename: "manifest.rspack.json") }
          .to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError, /gdk status rspack/)
      end

      it "names the webpack service when the webpack manifest is requested" do
        expect { described_class.asset_paths("entry1", manifest_filename: "manifest.json") }
          .to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError, /gdk status webpack/)
      end

      it "does not point at a webpack service when rspack is the bundler" do
        expect { described_class.asset_paths("entry1", manifest_filename: "manifest.rspack.json") }
          .to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError) { |error|
            expect(error.message).not_to include("gdk status webpack")
            expect(error.message).not_to include("webpack-dev-server")
          }
      end
    end

    describe "dev server SSL errors" do
      let(:original_error) { OpenSSL::SSL::SSLError.new("wrong version number") }

      before do
        allow(Gitlab::Webpack::FileLoader).to receive(:load).and_raise(
          Gitlab::Webpack::FileLoader::DevServerSSLError.new("https://localhost:3808/manifest", original_error)
        )
      end

      it "names the rspack dev server when the rspack manifest is requested" do
        expect { described_class.asset_paths("entry1", manifest_filename: "manifest.rspack.json") }
          .to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError) { |error|
            expect(error.message).to include("Could not connect to the rspack dev server")
            expect(error.message).not_to include("webpack dev server")
          }
      end

      it "names the webpack dev server when the webpack manifest is requested" do
        expect { described_class.asset_paths("entry1", manifest_filename: "manifest.json") }
          .to raise_error(Gitlab::Webpack::Manifest::ManifestLoadError, /Could not connect to the webpack dev server/)
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

      it "reads the manifest passed via manifest_filename instead of the default" do
        stub_file_read(::Rails.root.join("manifest_output/manifest.rspack.json"), content: manifest)

        expect(described_class.asset_paths("entry2", manifest_filename: "manifest.rspack.json"))
          .to eq(["/public_path/entry2.js"])
      end

      it "memoizes each manifest independently, keyed by filename" do
        rspack_manifest = <<-JSON
          {
            "errors": [],
            "assetsByChunkName": { "entry2": "entry2.rspack.js" }
          }
        JSON
        stub_file_read(::Rails.root.join("manifest_output/manifest.rspack.json"), content: rspack_manifest)

        expect(described_class.asset_paths("entry2")).to eq(["/public_path/entry2.js"])
        expect(described_class.asset_paths("entry2", manifest_filename: "manifest.rspack.json"))
          .to eq(["/public_path/entry2.rspack.js"])
        # The default manifest keeps its own cached value rather than the Rspack one.
        expect(described_class.asset_paths("entry2")).to eq(["/public_path/entry2.js"])
      end
    end
  end
end
