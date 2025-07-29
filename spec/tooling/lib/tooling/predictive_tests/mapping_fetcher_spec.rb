# frozen_string_literal: true

require_relative "../../../../../tooling/lib/tooling/predictive_tests/mapping_fetcher"

RSpec.describe Tooling::PredictiveTests::MappingFetcher, :aggregate_failures, feature_category: :tooling do
  subject(:mapping_fetcher) { described_class.new(logger: logger) }

  let(:crystalball_mapping) { "test-mapping.json" }
  let(:frontend_fixtures) { "ff_fixtures.json" }

  let(:logger) { Logger.new($stdout, level: :error) }
  let(:file_double) { instance_double(File, write: nil) }
  let(:open3_status) { instance_double(Process::Status, success?: extract_success) }

  let(:file_stat) do
    instance_double(File::Stat, size: 123, mtime: Time.parse("Tue, 01 Jan 2024 12:34:56 GMT"))
  end

  # rubocop:disable RSpec/VerifiedDoubles -- complains about message
  let(:get_http_response) do
    double(
      "HTTParty::Response",
      success?: http_success,
      code: 500,
      message: "message",
      headers: { "last-modified" => upstream_last_modified.httpdate }
    )
  end

  let(:head_http_response) do
    double(
      "HTTPParty::Response",
      success?: true,
      code: 200,
      headers: {
        "last-modified" => upstream_last_modified.httpdate,
        "content-length" => upstream_content
      }
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  let(:extract_success) { true }
  let(:http_success) { true }
  let(:upstream_last_modified) { Time.parse("Tue, 02 Jan 2024 12:34:56 GMT") }
  let(:upstream_content) { 123 }

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
    allow(described_class).to receive(:head)
      .with(
        %r{https://gitlab-org.gitlab.io/gitlab/crystalball/(packed-mapping.json.gz|frontend_fixtures_mapping.json)},
        timeout: 30
      )
      .and_return(head_http_response)
    allow(described_class).to receive(:get)
      .with(
        %r{https://gitlab-org.gitlab.io/gitlab/crystalball/(packed-mapping.json.gz|frontend_fixtures_mapping.json)},
        timeout: 30,
        stream_body: true
      )
      .and_yield("download fragment")
      .and_return(get_http_response)

    allow(Open3).to receive(:capture3).with(/gzip -d -c \S+mapping\.gz > \S+/).and_return(["out", "err", open3_status])
    # mock file operations only related to mapping fetcher
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(/mapping\.gz|#{frontend_fixtures}/, "ab").and_yield(file_double)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(/mapping\.json/).and_return(packed_mapping)
    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:write).with(crystalball_mapping, unpacked_mapping)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(/mapping\.gz|#{frontend_fixtures}/).and_return(true)
    allow(File).to receive(:utime).and_call_original
    allow(File).to receive(:utime).with(upstream_last_modified, upstream_last_modified, kind_of(String))
    allow(File).to receive(:stat).and_call_original
    allow(File).to receive(:stat).with(/mapping\.gz|#{frontend_fixtures}/).and_return(file_stat)
  end

  it "fetches rspec mappings" do
    expect(mapping_fetcher.fetch_rspec_mappings(crystalball_mapping)).to eq(crystalball_mapping)
    expect(described_class).to have_received(:get)
    expect(file_double).to have_received(:write).with("download fragment")
    expect(Open3).to have_received(:capture3).with(/gzip -d -c \S+mapping\.gz > \S+/)
    expect(File).to have_received(:write).with(crystalball_mapping, unpacked_mapping)
  end

  it "fetches frontend fixtures" do
    expect(mapping_fetcher.fetch_frontend_fixtures_mappings(frontend_fixtures)).to eq(frontend_fixtures)
    expect(described_class).to have_received(:get)
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

  context "with files being cached" do
    let(:upstream_last_modified) { Time.parse("Tue, 01 Jan 2024 12:34:56 GMT") }

    it "skips downloading rspec mapping archive" do
      expect(mapping_fetcher.fetch_rspec_mappings(crystalball_mapping)).to eq(crystalball_mapping)
      expect(described_class).not_to have_received(:get)
    end

    it "skips downloading frontend fixtures" do
      expect(mapping_fetcher.fetch_frontend_fixtures_mappings(frontend_fixtures)).to eq(frontend_fixtures)
      expect(described_class).not_to have_received(:get)
    end
  end
end
