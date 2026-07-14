# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require 'tmpdir'

require_relative '../../../scripts/coverage/per_test_coverage_artifact_downloader'

RSpec.describe PerTestCoverageArtifactDownloader, feature_category: :tooling do
  let(:api_url) { 'https://gitlab.example.com/api/v4' }
  let(:project_id) { '12345' }
  let(:pipeline_id) { '67890' }
  let(:job_token) { 'token123' }
  let(:child_pipeline_id) { 11111 }
  let(:output_dir) { Dir.mktmpdir('per-test-coverage-spec') }
  let(:pattern) { /\Arspec(-ee)? .+ per-test-coverage\z/ }

  let(:env_vars) do
    {
      'CI_API_V4_URL' => api_url,
      'CI_PROJECT_ID' => project_id,
      'CI_PIPELINE_ID' => pipeline_id,
      'CI_JOB_TOKEN' => job_token
    }
  end

  subject(:downloader) do
    described_class.new(job_name_pattern: pattern, output_dir: output_dir)
  end

  before do
    stub_const('ENV', env_vars)
    allow(downloader).to receive(:puts)
    allow(downloader).to receive(:warn)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  def stub_bridges(body)
    stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
      .with(headers: { 'JOB-TOKEN' => job_token })
      .to_return(status: 200, body: body.to_json)
  end

  def stub_jobs(jobs, page: 1)
    stub_request(:get,
      "#{api_url}/projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs?per_page=100&page=#{page}")
      .with(headers: { 'JOB-TOKEN' => job_token })
      .to_return(status: 200, body: jobs.to_json)
  end

  describe '#run' do
    context 'when the bridge has not fired (no child pipeline)' do
      before do
        stub_bridges([])
      end

      it 'returns 0 (no-op success)' do
        expect(downloader.run).to eq(0)
      end
    end

    context 'when the bridges endpoint returns no matching bridge name' do
      before do
        stub_bridges([
          { 'name' => 'unrelated:trigger', 'downstream_pipeline' => { 'id' => 9999 } }
        ])
      end

      it 'returns 0 (no-op success)' do
        expect(downloader.run).to eq(0)
      end
    end

    context 'when no jobs in the child pipeline match the pattern' do
      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs([
          { 'id' => 1, 'name' => 'something-else' },
          { 'id' => 2, 'name' => 'rspec migration' } # missing per-test-coverage suffix
        ])
      end

      it 'returns 1 so the export job surfaces missing artifacts' do
        expect(downloader.run).to eq(1)
      end
    end

    context 'when matching jobs are found and downloads succeed' do
      let(:matching_jobs) do
        [
          { 'id' => 100, 'name' => 'rspec unit per-test-coverage' },
          { 'id' => 101, 'name' => 'rspec-ee system per-test-coverage' },
          { 'id' => 102, 'name' => 'something-unrelated' }
        ]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)

        stub_request(:get, %r{/projects/#{project_id}/jobs/(100|101)/artifacts})
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')

        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'downloads from each matching job (skipping non-matching)' do
        downloader.run

        expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts").once
        expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/101/artifacts").once
        expect(WebMock)
          .not_to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/102/artifacts")
      end

      it 'returns 0 when every download succeeds' do
        expect(downloader.run).to eq(0)
      end
    end

    context 'when a download returns non-2xx' do
      let(:matching_jobs) do
        [{ 'id' => 100, 'name' => 'rspec unit per-test-coverage' }]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 500, body: 'boom')
      end

      it 'returns 1' do
        expect(downloader.run).to eq(1)
      end
    end

    context 'when some downloads succeed and others fail' do
      let(:matching_jobs) do
        [
          { 'id' => 100, 'name' => 'rspec unit per-test-coverage' },
          { 'id' => 101, 'name' => 'rspec-ee system per-test-coverage' }
        ]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/101/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 500, body: 'boom')

        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'returns 1 because all matching shards must succeed' do
        expect(downloader.run).to eq(1)
      end
    end

    context 'when unzip fails on the downloaded artifact' do
      let(:matching_jobs) do
        [{ 'id' => 100, 'name' => 'rspec unit per-test-coverage' }]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'corrupt-zip-bytes')
        allow(downloader).to receive(:system).with('unzip', any_args).and_return(false)
      end

      it 'returns 1' do
        expect(downloader.run).to eq(1)
      end
    end

    context 'when the artifacts endpoint loops past the redirect limit' do
      let(:matching_jobs) do
        [{ 'id' => 100, 'name' => 'rspec unit per-test-coverage' }]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redir/1" })
        stub_request(:get, %r{#{Regexp.escape(api_url)}/redir/\d+})
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redir/2" })
      end

      it 'returns 1 (bails after the redirect cap)' do
        expect(downloader.run).to eq(1)
      end
    end

    context 'when a redirect Location is relative' do
      let(:matching_jobs) do
        [{ 'id' => 100, 'name' => 'rspec unit per-test-coverage' }]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)

        # Workhorse occasionally emits a relative Location. We resolve it
        # against the previous URI so we land on the same host. An absolute
        # path replaces the entire path component, dropping /api/v4; that's
        # standard RFC 3986 reference resolution.
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .to_return(status: 302, headers: { 'Location' => '/dl/artifacts/100' })
        stub_request(:get, 'https://gitlab.example.com/dl/artifacts/100')
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')

        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'resolves the relative Location and downloads successfully' do
        expect(downloader.run).to eq(0)
      end
    end

    context 'when the artifacts endpoint redirects to a different host (e.g. GCS)' do
      let(:matching_jobs) do
        [{ 'id' => 100, 'name' => 'rspec unit per-test-coverage' }]
      end

      let(:gcs_url) { 'https://storage.googleapis.com/gitlab-artifacts/100.zip' }

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 302, headers: { 'Location' => gcs_url })

        # The follow-up request must NOT carry the JOB-TOKEN header. WebMock
        # asserts on the header set being absent below.
        stub_request(:get, gcs_url).to_return(status: 200, body: 'fake-zip-bytes')

        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'drops the JOB-TOKEN header on cross-host redirects' do
        expect(downloader.run).to eq(0)
        expect(WebMock).to have_requested(:get, gcs_url)
          .with { |req| !req.headers.key?('Job-Token') && !req.headers.key?('JOB-TOKEN') }
      end
    end

    context 'when the bridges API errors out' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .to_return(status: 500, body: 'oops')
      end

      it 'raises with the HTTP status surfaced' do
        expect { downloader.run }.to raise_error(/API request failed.*HTTP 500/)
      end
    end

    context 'when the child pipeline has more than 100 jobs (pagination)' do
      let(:pattern) { /per-test-coverage/ } # broad enough to match shard names on both pages
      let(:page1) { Array.new(100) { |i| { 'id' => i, 'name' => "rspec unit per-test-coverage #{i + 1}/100" } } }
      let(:page2) { [{ 'id' => 200, 'name' => 'rspec system per-test-coverage' }] }

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(page1, page: 1)
        stub_jobs(page2, page: 2)

        stub_request(:get, %r{/projects/#{project_id}/jobs/\d+/artifacts})
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')

        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'walks every page to discover all matching jobs' do
        expect(downloader.run).to eq(0)
        # WebMock normalises query params alphabetically. Anchor on `page=N&`
        # so per_page=100 (which contains "page=1") doesn't false-match.
        expect(WebMock).to have_requested(:get, /jobs\?page=1&/).once
        expect(WebMock).to have_requested(:get, /jobs\?page=2&/).once
      end
    end

    context 'when a process command and output glob are configured (streaming)' do
      let(:matching_jobs) do
        [
          { 'id' => 100, 'name' => 'rspec unit per-test-coverage 1/3' },
          { 'id' => 101, 'name' => 'rspec unit per-test-coverage 2/3' },
          { 'id' => 102, 'name' => 'rspec unit per-test-coverage 3/3' }
        ]
      end

      let(:pattern) { /per-test-coverage/ }
      let(:output_glob) { File.join(output_dir, 'shard-*.ndjson') }
      let(:process_command) { 'echo processing' }

      subject(:downloader) do
        described_class.new(
          job_name_pattern: pattern,
          output_dir: output_dir,
          process_command: process_command,
          output_glob: output_glob,
          batch_size: 2
        )
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
        stub_request(:get, %r{/projects/#{project_id}/jobs/(100|101|102)/artifacts})
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')

        # Stand in for `unzip` by writing one ndjson per extracted shard, so the
        # clear step has real files to remove.
        extracted = 0
        allow(downloader).to receive(:system).with('unzip', any_args) do
          extracted += 1
          File.write(File.join(output_dir, "shard-#{extracted}.ndjson"), "{}\n")
          true
        end
        allow(downloader).to receive(:system).with(process_command).and_return(true)
      end

      it 'runs the process command once per batch (3 shards, batch size 2 => 2 batches)' do
        downloader.run

        expect(downloader).to have_received(:system).with(process_command).twice
      end

      it 'deletes the extracted files after processing so they do not accumulate' do
        downloader.run

        expect(Dir.glob(output_glob)).to be_empty
      end

      it 'returns 0 when every shard downloads and processes' do
        expect(downloader.run).to eq(0)
      end

      it 'returns 1 when the process command fails for a batch' do
        allow(downloader).to receive(:system).with(process_command).and_return(false)

        expect(downloader.run).to eq(1)
      end

      it 'clears each batch before the next, so disk never holds more than one batch' do
        seen = []
        allow(downloader).to receive(:system).with(process_command) do
          seen << Dir.glob(output_glob).map { |path| File.basename(path) }.sort
          true
        end

        downloader.run

        # 3 shards, batch size 2 => batches of 2 then 1. Each process call sees
        # only its own batch's files (the previous batch was cleared), which a
        # download-everything-then-clear-once model could not satisfy.
        expect(seen.map(&:size)).to eq([2, 1])
        expect(seen[1] & seen[0]).to be_empty
      end
    end

    context 'when running as one node of a parallel export (CI_NODE_INDEX and CI_NODE_TOTAL)' do
      let(:env_vars) { super().merge('CI_NODE_INDEX' => '1', 'CI_NODE_TOTAL' => '2') }
      let(:pattern) { /per-test-coverage/ }
      let(:matching_jobs) do
        [
          { 'id' => 100, 'name' => 'rspec unit per-test-coverage 1/4' },
          { 'id' => 101, 'name' => 'rspec unit per-test-coverage 2/4' },
          { 'id' => 102, 'name' => 'rspec unit per-test-coverage 3/4' },
          { 'id' => 103, 'name' => 'rspec unit per-test-coverage 4/4' }
        ]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
        stub_request(:get, %r{/projects/#{project_id}/jobs/\d+/artifacts})
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake-zip-bytes')
        allow(downloader).to receive(:system).with('unzip', any_args).and_return(true)
      end

      it 'downloads only this node\'s round-robin slice of the sorted shards', :aggregate_failures do
        expect(downloader.run).to eq(0)

        # Node 1 of 2 over sorted ids [100, 101, 102, 103] (positions 0..3) keeps
        # the even positions, so it owns 100 and 102 and leaves 101 and 103 to node 2.
        expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/100/artifacts").once
        expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/102/artifacts").once
        expect(WebMock).not_to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/101/artifacts")
        expect(WebMock).not_to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/103/artifacts")
      end
    end

    context 'when this node owns no shards in its slice' do
      let(:env_vars) { super().merge('CI_NODE_INDEX' => '4', 'CI_NODE_TOTAL' => '4') }
      let(:pattern) { /per-test-coverage/ }
      let(:matching_jobs) do
        [
          { 'id' => 100, 'name' => 'rspec unit per-test-coverage 1/2' },
          { 'id' => 101, 'name' => 'rspec unit per-test-coverage 2/2' }
        ]
      end

      before do
        stub_bridges([
          { 'name' => described_class::BRIDGE_NAME,
            'downstream_pipeline' => { 'id' => child_pipeline_id } }
        ])
        stub_jobs(matching_jobs)
      end

      it 'returns 0 without downloading anything (fewer shards than nodes)' do
        expect(downloader.run).to eq(0)
        expect(WebMock).not_to have_requested(:get, %r{/projects/#{project_id}/jobs/\d+/artifacts})
      end
    end

    context 'when a process command is set without an output glob' do
      it 'raises so the unbounded-disk misconfiguration fails loudly' do
        expect do
          described_class.new(
            job_name_pattern: pattern, output_dir: output_dir, process_command: 'echo x'
          )
        end.to raise_error(ArgumentError, /output_glob/)
      end
    end
  end

  describe '.shards_for_node' do
    let(:jobs) { (1..10).map { |i| { 'id' => i, 'name' => "rspec #{i} per-test-coverage" } } }

    it 'returns every job unchanged for a single node' do
      expect(described_class.shards_for_node(jobs, node_index: 1, node_total: 1)).to eq(jobs)
    end

    it 'splits the jobs into disjoint slices that cover every job exactly once' do
      ids = (1..4).flat_map do |node|
        described_class.shards_for_node(jobs, node_index: node, node_total: 4).map { |job| job['id'] }
      end

      expect(ids).to match_array(1..10)
    end

    it 'balances the shard count across nodes to within one' do
      sizes = (1..4).map { |node| described_class.shards_for_node(jobs, node_index: node, node_total: 4).size }

      expect(sizes.max - sizes.min).to be <= 1
    end

    it 'computes the same slice regardless of the order the jobs arrive in' do
      expect(described_class.shards_for_node(jobs.reverse, node_index: 2, node_total: 4))
        .to eq(described_class.shards_for_node(jobs, node_index: 2, node_total: 4))
    end

    it 'gives a node an empty slice when there are fewer jobs than nodes' do
      expect(described_class.shards_for_node(jobs.first(2), node_index: 4, node_total: 4)).to be_empty
    end
  end
end
