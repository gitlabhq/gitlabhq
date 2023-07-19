# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Webpack::FileLoader do
  include FileReadHelpers
  include WebMock::API

  let(:error_file_path) { "error.yml" }
  let(:file_path) { "my_test_file.yml" }
  let(:file_contents) do
    <<-EOF
    - hello
    - world
    - test
    EOF
  end

  before do
    allow(Gitlab.config.webpack.dev_server).to receive_messages(host: 'hostname', port: 2000, https: false)
    allow(Gitlab.config.webpack).to receive(:public_path).and_return('public_path')
    allow(Gitlab.config.webpack).to receive(:output_dir).and_return('webpack_output')
  end

  context "with dev server enabled" do
    before do
      allow(Gitlab.config.webpack.dev_server).to receive(:enabled).and_return(true)

      stub_request(:get, "http://hostname:2000/public_path/not_found").to_return(status: 404)
      stub_request(:get, "http://hostname:2000/public_path/#{file_path}").to_return(body: file_contents, status: 200)
      stub_request(:get, "http://hostname:2000/public_path/#{error_file_path}").to_raise(StandardError)
    end

    it "returns content when responds successfully" do
      expect(described_class.load(file_path)).to eq(file_contents)
    end

    it "raises error when 404" do
      expect { described_class.load("not_found") }.to raise_error("HTTP error 404")
    end

    it "raises error when errors out" do
      expect { described_class.load(error_file_path) }.to raise_error(Gitlab::Webpack::FileLoader::DevServerLoadError)
    end
  end

  context "with dev server enabled and https" do
    before do
      allow(Gitlab.config.webpack.dev_server).to receive(:enabled).and_return(true)
      allow(Gitlab.config.webpack.dev_server).to receive(:https).and_return(true)

      stub_request(:get, "https://hostname:2000/public_path/#{error_file_path}").to_raise(EOFError)
    end

    it "raises error if catches SSLError" do
      expect { described_class.load(error_file_path) }.to raise_error(Gitlab::Webpack::FileLoader::DevServerSSLError)
    end
  end

  context "with dev server disabled" do
    before do
      allow(Gitlab.config.webpack.dev_server).to receive(:enabled).and_return(false)
      stub_file_read(::Rails.root.join("webpack_output/#{file_path}"), content: file_contents)
      stub_file_read(::Rails.root.join("webpack_output/#{error_file_path}"), error: Errno::ENOENT)
    end

    describe ".load" do
      it "returns file content from file path" do
        expect(described_class.load(file_path)).to be(file_contents)
      end

      it "throws error if file cannot be read" do
        expect { described_class.load(error_file_path) }.to raise_error(Gitlab::Webpack::FileLoader::StaticLoadError)
      end
    end
  end
end
