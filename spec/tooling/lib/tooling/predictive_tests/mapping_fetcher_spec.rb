# frozen_string_literal: true

require_relative "../../../../../tooling/lib/tooling/predictive_tests/mapping_fetcher"

RSpec.describe Tooling::PredictiveTests::MappingFetcher, :aggregate_failures, feature_category: :tooling do
  subject(:mapping_fetcher) { described_class.new(logger: logger) }

  let(:crystalball_mapping) { "test-mapping.json" }
  let(:frontend_fixtures) { "ff_fixtures.json" }

  let(:logger) { Logger.new(StringIO.new) }
  let(:file_double) { instance_double(File, write: nil) }
  let(:http_response) { double("HTTParty::Response", success?: http_success, code: 500, message: "message") } # rubocop:disable RSpec/VerifiedDoubles -- complains about message
  let(:open3_status) { instance_double(Process::Status, success?: extract_success) }

  let(:extract_success) { true }
  let(:http_success) { true }

  let(:unpacked_mapping) { JSON.generate(Tooling::TestMapPacker.new.unpack(JSON.parse(packed_mapping))) } # rubocop:disable Gitlab/Json -- non rails code
  let(:packed_mapping) do
    <<~JSON
      {
        "gems/activerecord-gitlab/lib/active_record/gitlab_patches/rescue_from.rb": {
          "ee": {
            "spec": {
              "lib": {
                "ee": {
                  "gitlab": {
                    "background_migration": {
                      "backfill_security_policies_spec.rb": 1,
                      "backfill_duo_core_for_existing_subscription_spec.rb": 1
                    }
                  }
                }
              }
            }
          }
        }
      }
    JSON
  end

  before do
    allow(described_class).to receive(:get)
      .with(
        %r{https://gitlab-org.gitlab.io/gitlab/crystalball/(packed-mapping.json.gz|frontend_fixtures_mapping.json)},
        timeout: 30,
        stream_body: true
      )
      .and_yield("download fragment")
      .and_return(http_response)

    allow(Open3).to receive(:capture3).with(/gzip -d -c \S+mapping\.gz > \S+/).and_return(["out", "err", open3_status])
    # mock file operations only related to mapping fetcher
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(/mapping\.gz|#{frontend_fixtures}/, "ab").and_yield(file_double)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(/mapping\.json/).and_return(packed_mapping)
    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:write).with(crystalball_mapping, unpacked_mapping)
  end

  it "fetches rspec mappings" do
    expect(mapping_fetcher.fetch_rspec_mappings(crystalball_mapping)).to eq(crystalball_mapping)
    expect(file_double).to have_received(:write).with("download fragment")
    expect(File).to have_received(:write).with(crystalball_mapping, unpacked_mapping)
  end

  it "fetches frontend fixtures" do
    expect(mapping_fetcher.fetch_frontend_fixtures_mappings(frontend_fixtures)).to eq(frontend_fixtures)
    expect(file_double).to have_received(:write).with("download fragment")
  end

  context "with download failure" do
    let(:http_success) { false }

    it "rspec mapping download raises an error" do
      expect { mapping_fetcher.fetch_rspec_mappings(crystalball_mapping) }.to raise_error(
        StandardError, "Download failed with status 500: message"
      )
    end

    it "frontend fixture download raises an error" do
      expect { mapping_fetcher.fetch_frontend_fixtures_mappings(frontend_fixtures) }.to raise_error(
        StandardError, "Download failed with status 500: message"
      )
    end
  end

  context "with extraction failure" do
    let(:extract_success) { false }

    it "raises an error" do
      expect { mapping_fetcher.fetch_rspec_mappings(crystalball_mapping) }.to raise_error(
        StandardError, /Failed to extract archive \S+mapping\.gz: err/
      )
    end
  end
end
