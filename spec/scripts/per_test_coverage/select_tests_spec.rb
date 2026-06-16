# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'fileutils'

require_relative '../../../scripts/per_test_coverage/select_tests'

RSpec.describe PerTestCoverage::SelectTests, :silence_stdout, feature_category: :tooling do
  let(:clickhouse_client) { instance_double(GitlabQuality::TestTooling::ClickHouse::Client) }
  let(:gitlab_api) { instance_double(PerTestCoverage::SelectTests::GitlabApi) }
  let(:git) { instance_double(PerTestCoverage::SelectTests::Git) }
  let(:project_path) { 'gitlab-org/gitlab' }
  let(:output_dir) { Dir.mktmpdir('per-test-coverage-spec') }
  let(:foss_queue_path) { File.join(output_dir, 'per-test-coverage-queue-foss.txt') }
  let(:ee_queue_path) { File.join(output_dir, 'per-test-coverage-queue-ee.txt') }
  let(:jest_queue_path) { File.join(output_dir, 'per-test-coverage-queue-jest.txt') }
  let(:all_test_files) do
    %w[
      spec/models/user_spec.rb
      spec/services/foo_spec.rb
      spec/frontend/foo_spec.js
      ee/spec/models/license_spec.rb
      ee/spec/services/bar_spec.rb
      ee/spec/frontend/bar_spec.js
      qa/qa/specs/features/foo_spec.rb
    ]
  end

  subject(:select_tests) do
    described_class.new(
      clickhouse_client: clickhouse_client,
      gitlab_api: gitlab_api,
      now: now,
      git: git,
      project_path: project_path,
      output_dir: output_dir,
      test_file_glob: -> { all_test_files }
    )
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  shared_examples 'writes the expected queues' do |foss:, ee:, jest: []|
    it "writes FOSS, EE, and jest queue files" do
      expect { select_tests.run! }.not_to raise_error
      expect(File.read(foss_queue_path).split("\n")).to match_array(foss)
      expect(File.read(ee_queue_path).split("\n")).to match_array(ee)
      expect(File.read(jest_queue_path).split("\n")).to match_array(jest)
    end
  end

  describe '#run!' do
    context 'when running on a weekday (Tuesday 10:00 UTC)' do
      let(:now) { Time.utc(2026, 5, 12, 10, 0, 0) } # Tuesday

      let(:last_capture_sha) { 'abc123def456' }
      let(:changed_source_files) { %w[app/models/user.rb lib/foo.rb] }
      let(:new_spec_files) { %w[spec/models/new_thing_spec.rb] }
      let(:tests_covering_changed) { %w[spec/models/user_spec.rb ee/spec/services/user_service_spec.rb] }
      let(:stale_tests) { %w[spec/services/foo_spec.rb] }

      before do
        allow(clickhouse_client).to receive(:query).with(/max\(captured_sha\)/,
          anything).and_return([{ 'sha' => last_capture_sha }])
        allow(git).to receive(:diff_files).with(last_capture_sha,
          described_class::SOURCE_FILE_PATHS).and_return(changed_source_files)
        allow(git).to receive(:diff_files).with(last_capture_sha,
          described_class::SPEC_FILE_PATHS).and_return(new_spec_files)
        allow(clickhouse_client).to receive(:query).with(/test_files_by_source_file/, anything).and_return(
          tests_covering_changed.map { |t| { 'test_file' => t } }
        )
        allow(clickhouse_client).to receive(:query).with(/INTERVAL 14 DAY/, anything).and_return(
          stale_tests.map { |t| { 'test_file' => t } }
        )
      end

      it 'does not consult the GitLab API for weekday slots' do
        expect(gitlab_api).not_to receive(:count_schedule_pipelines_since)

        select_tests.run!
      end

      it 'queries ClickHouse for last_capture_sha, delta tests, and stale-rescue tests' do
        select_tests.run!

        expect(clickhouse_client).to have_received(:query).with(/max\(captured_sha\)/, anything).once
        expect(clickhouse_client).to have_received(:query).with(/test_files_by_source_file/, anything).once
        expect(clickhouse_client).to have_received(:query).with(/INTERVAL 14 DAY/, anything).once
      end

      it_behaves_like 'writes the expected queues',
        foss: %w[spec/models/user_spec.rb spec/models/new_thing_spec.rb spec/services/foo_spec.rb],
        ee: %w[ee/spec/services/user_service_spec.rb]

      context 'when both queues end up empty' do
        let(:changed_source_files) { [] }
        let(:new_spec_files) { [] }
        let(:tests_covering_changed) { [] }
        let(:stale_tests) { [] }

        it 'exits with sentinel status 2' do
          expect { select_tests.run! }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(2)
          end
        end
      end

      context 'when the delta covers tests that are also in the stale-rescue result' do
        let(:tests_covering_changed) { %w[spec/services/foo_spec.rb spec/models/user_spec.rb] }
        let(:stale_tests) { %w[spec/services/foo_spec.rb spec/other_spec.rb] }

        it_behaves_like 'writes the expected queues',
          foss: %w[spec/services/foo_spec.rb spec/models/user_spec.rb spec/other_spec.rb spec/models/new_thing_spec.rb],
          ee: []
      end

      context 'when no source files have changed but new spec files exist' do
        let(:changed_source_files) { [] }
        let(:tests_covering_changed) { [] }

        it 'still queues new spec files plus stale-rescue' do
          select_tests.run!

          # We should NOT call the source-to-test MV when there are no changed source files
          expect(clickhouse_client).not_to have_received(:query).with(/test_files_by_source_file/, anything)
          # New spec files + stale should be in FOSS queue
          expect(File.read(foss_queue_path).split("\n")).to match_array(
            %w[spec/models/new_thing_spec.rb spec/services/foo_spec.rb]
          )
        end
      end
    end

    # Weekend bucket slot logic. The script asks the GitLab API how many
    # maintenance-schedule pipelines have fired since the most recent
    # Saturday 00:00 UTC. 0 prior pipelines means bucket 0, 1 prior means
    # bucket 1, 2+ prior falls through to the weekday delta + stale-rescue
    # path.
    describe 'weekend bucket sweep' do
      let(:weekend_start) { Time.utc(2026, 5, 16, 0, 0, 0) } # Saturday 00:00 UTC

      shared_examples 'queues hash-bucket' do |bucket:|
        it "queues only files whose hash mod 2 equals #{bucket}" do
          select_tests.run!

          queued = File.read(foss_queue_path).split("\n") +
            File.read(ee_queue_path).split("\n") +
            File.read(jest_queue_path).split("\n")
          queued.reject!(&:empty?)
          expect(queued).not_to be_empty, "bucket #{bucket} should match at least one fixture file"
          queued.each do |path|
            expect(Digest::SHA256.hexdigest(path).to_i(16) % 2).to eq(bucket)
          end
        end

        it 'asks the GitLab API for prior pipelines since the weekend start' do
          select_tests.run!

          expect(gitlab_api).to have_received(:count_schedule_pipelines_since).with(
            schedule_id: described_class::MAINTENANCE_SCHEDULE_ID,
            since_time: weekend_start,
            exclude_pipeline_id: nil
          )
        end

        it 'does not touch ClickHouse' do
          select_tests.run!

          expect(clickhouse_client).not_to have_received(:query)
        end
      end

      before do
        allow(clickhouse_client).to receive(:query)
        # Default for this describe block; the dedicated "CI_PIPELINE_ID is set"
        # context overrides it. CI runners always have CI_PIPELINE_ID set, so
        # leaving it on would leak that value into exclude_pipeline_id and break
        # the assertions that expect nil.
        stub_env('CI_PIPELINE_ID', nil)
      end

      context 'when this is the first weekend slot (Saturday 00:00 UTC, 0 prior pipelines)' do
        let(:now) { weekend_start }

        before do
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(0)
        end

        it_behaves_like 'queues hash-bucket', bucket: 0
      end

      context 'when this is the second weekend slot (Saturday 02:00 UTC, 1 prior pipeline)' do
        let(:now) { Time.utc(2026, 5, 16, 2, 0, 0) }

        before do
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(1)
        end

        it_behaves_like 'queues hash-bucket', bucket: 1
      end

      context 'when sliding forward because 00:00 missed so Saturday 02:00 UTC sees 0 prior' do
        let(:now) { Time.utc(2026, 5, 16, 2, 0, 0) }

        before do
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(0)
        end

        it_behaves_like 'queues hash-bucket', bucket: 0
      end

      context 'when this is the third weekend slot onward (2+ prior pipelines)' do
        let(:now) { Time.utc(2026, 5, 16, 4, 0, 0) } # Saturday 04:00 UTC
        let(:last_capture_sha) { 'sha' }

        before do
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(2)
          # Falls through to weekday queries.
          allow(clickhouse_client).to receive(:query).with(/max\(captured_sha\)/, anything)
            .and_return([{ 'sha' => last_capture_sha }])
          allow(git).to receive(:diff_files).and_return([])
          allow(clickhouse_client).to receive(:query).with(/INTERVAL 14 DAY/, anything).and_return(
            [{ 'test_file' => 'spec/models/user_spec.rb' }]
          )
        end

        it 'runs the weekday delta path instead of the bucket sweep' do
          select_tests.run!

          expect(clickhouse_client).to have_received(:query).with(/max\(captured_sha\)/, anything)
          expect(clickhouse_client).to have_received(:query).with(/INTERVAL 14 DAY/, anything)
          expect(File.read(foss_queue_path).split("\n")).to eq(%w[spec/models/user_spec.rb])
        end
      end

      context 'when on Sunday with the Saturday sweep already done (many prior pipelines)' do
        let(:now) { Time.utc(2026, 5, 17, 12, 0, 0) } # Sunday 12:00 UTC

        before do
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(18)
          allow(clickhouse_client).to receive(:query).with(/max\(captured_sha\)/, anything)
            .and_return([{ 'sha' => 'sha' }])
          allow(git).to receive(:diff_files).and_return([])
          allow(clickhouse_client).to receive(:query).with(/INTERVAL 14 DAY/, anything).and_return([])
        end

        it 'uses Saturday 00:00 UTC as the weekend anchor and runs weekday delta' do
          expect { select_tests.run! }.to raise_error(SystemExit) # empty queue, exit 2 sentinel

          expect(gitlab_api).to have_received(:count_schedule_pipelines_since).with(
            schedule_id: described_class::MAINTENANCE_SCHEDULE_ID,
            since_time: weekend_start, # Saturday 00:00 UTC, not Sunday 00:00
            exclude_pipeline_id: nil
          )
        end
      end

      context 'when CI_PIPELINE_ID is set' do
        let(:now) { weekend_start }

        before do
          stub_env('CI_PIPELINE_ID', '999')
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(0)
        end

        it 'passes the current pipeline id so it is excluded from the count' do
          select_tests.run!

          expect(gitlab_api).to have_received(:count_schedule_pipelines_since).with(
            hash_including(exclude_pipeline_id: 999)
          )
        end
      end

      context 'when CI_PIPELINE_ID is unset' do
        let(:now) { weekend_start }

        before do
          # stub_env(..., nil) deletes the key, so the script reads nil from ENV.
          stub_env('CI_PIPELINE_ID', nil)
          allow(gitlab_api).to receive(:count_schedule_pipelines_since).and_return(0)
        end

        it 'passes exclude_pipeline_id: nil' do
          select_tests.run!

          expect(gitlab_api).to have_received(:count_schedule_pipelines_since).with(
            hash_including(exclude_pipeline_id: nil)
          )
        end
      end
    end

    # GLCI_PER_TEST_COVERAGE_FORCE_BUCKET forces a full-glob bucket sweep on any
    # day, bypassing the weekday delta and the weekend API decision.
    describe 'forced bucket override' do
      let(:now) { Time.utc(2026, 5, 12, 10, 0, 0) } # Tuesday, to prove the day is ignored

      before do
        stub_env('CI_PIPELINE_ID', nil)
        allow(gitlab_api).to receive(:count_schedule_pipelines_since)
        # Weekday-path stubs so that, without the feature, run! completes and the
        # bucket assertions fail rather than erroring on a nil ClickHouse result.
        allow(clickhouse_client).to receive(:query).with(/max\(captured_sha\)/, anything)
          .and_return([{ 'sha' => 'sha' }])
        allow(git).to receive(:diff_files).and_return([])
        allow(clickhouse_client).to receive(:query).with(/INTERVAL 14 DAY/, anything)
          .and_return(all_test_files.map { |t| { 'test_file' => t } })
      end

      shared_examples 'a forced bucket sweep' do |bucket:|
        it "queues only hash-bucket #{bucket} files, skipping ClickHouse and the GitLab API",
          :aggregate_failures do
          select_tests.run!

          queued = (File.read(foss_queue_path).split("\n") +
            File.read(ee_queue_path).split("\n") +
            File.read(jest_queue_path).split("\n")).reject(&:empty?)

          expect(queued).not_to be_empty
          queued.each { |path| expect(Digest::SHA256.hexdigest(path).to_i(16) % 2).to eq(bucket) }
          expect(clickhouse_client).not_to have_received(:query)
          expect(gitlab_api).not_to have_received(:count_schedule_pipelines_since)
        end
      end

      context 'when set to 0' do
        before do
          stub_env('GLCI_PER_TEST_COVERAGE_FORCE_BUCKET', '0')
        end

        it_behaves_like 'a forced bucket sweep', bucket: 0
      end

      context 'when set to 1' do
        before do
          stub_env('GLCI_PER_TEST_COVERAGE_FORCE_BUCKET', '1')
        end

        it_behaves_like 'a forced bucket sweep', bucket: 1
      end

      context 'when set to an out-of-range value' do
        before do
          stub_env('GLCI_PER_TEST_COVERAGE_FORCE_BUCKET', '5')
        end

        it 'raises a clear error' do
          expect { select_tests.run! }.to raise_error(/must be 0 or 1/)
        end
      end

      context 'when set to a non-integer string' do
        before do
          stub_env('GLCI_PER_TEST_COVERAGE_FORCE_BUCKET', 'abc')
        end

        it 'raises a clear error' do
          expect { select_tests.run! }.to raise_error(/must be 0 or 1/)
        end
      end
    end

    context 'when categorising FOSS vs EE vs jest by path' do
      let(:now) { Time.utc(2026, 5, 12, 10, 0, 0) } # Tuesday

      before do
        allow(clickhouse_client).to receive(:query).with(/max\(captured_sha\)/,
          anything).and_return([{ 'sha' => 'sha' }])
        allow(git).to receive(:diff_files).and_return([])
        allow(clickhouse_client).to receive(:query).with(/INTERVAL 14 DAY/, anything).and_return(
          [
            { 'test_file' => 'spec/models/user_spec.rb' },         # FOSS rspec
            { 'test_file' => 'spec/frontend/foo_spec.js' },        # jest
            { 'test_file' => 'ee/spec/models/license_spec.rb' },   # EE rspec
            { 'test_file' => 'ee/spec/frontend/bar_spec.js' },     # jest (ee/ prefix, but jest)
            { 'test_file' => 'qa/qa/specs/features/foo_spec.rb' }  # FOSS rspec (qa is not ee)
          ]
        )
      end

      it 'splits rspec into FOSS/EE by ee/ prefix and routes _spec.js files to jest' do
        select_tests.run!

        expect(File.read(foss_queue_path).split("\n")).to match_array(
          %w[spec/models/user_spec.rb qa/qa/specs/features/foo_spec.rb]
        )
        expect(File.read(ee_queue_path).split("\n")).to match_array(
          %w[ee/spec/models/license_spec.rb]
        )
        expect(File.read(jest_queue_path).split("\n")).to match_array(
          %w[spec/frontend/foo_spec.js ee/spec/frontend/bar_spec.js]
        )
      end
    end
  end
end

RSpec.describe PerTestCoverage::SelectTests::GitlabApi, :silence_stdout, feature_category: :tooling do
  let(:api_url) { 'https://gitlab.example/api/v4' }
  let(:project_id) { '278964' }
  let(:job_token) { 'fake-token' }
  let(:since_time) { Time.utc(2026, 5, 16, 0, 0, 0) }
  let(:schedule_id) { 23_503 }
  let(:expected_url) do
    URI.parse("#{api_url}/projects/#{project_id}/pipeline_schedules/#{schedule_id}/pipelines?per_page=100")
  end

  subject(:client) do
    described_class.new(api_url: api_url, project_id: project_id, job_token: job_token)
  end

  def stub_http_get(code:, body:)
    response = instance_double(Net::HTTPResponse, code: code.to_s, body: body)
    http = instance_double(Net::HTTP)
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
    response
  end

  describe '#count_schedule_pipelines_since' do
    it 'counts pipelines created at or after since_time' do
      stub_http_get(code: 200, body: Gitlab::Json.dump([
        { 'id' => 1, 'created_at' => '2026-05-16T01:00:00Z' },
        { 'id' => 2, 'created_at' => '2026-05-15T22:00:00Z' }
      ]))

      count = client.count_schedule_pipelines_since(schedule_id: schedule_id, since_time: since_time)

      expect(count).to eq(1)
    end

    it 'excludes the current pipeline id' do
      stub_http_get(code: 200, body: Gitlab::Json.dump([
        { 'id' => 1, 'created_at' => '2026-05-16T01:00:00Z' },
        { 'id' => 999, 'created_at' => '2026-05-16T02:00:00Z' }
      ]))

      count = client.count_schedule_pipelines_since(
        schedule_id: schedule_id, since_time: since_time, exclude_pipeline_id: 999)

      expect(count).to eq(1)
    end

    it 'sends the JOB-TOKEN header when one is configured' do
      response = stub_http_get(code: 200, body: '[]')

      client.count_schedule_pipelines_since(schedule_id: schedule_id, since_time: since_time)

      expect(response).to have_received(:code).at_least(:once)
    end

    it 'raises on a non-2xx response' do
      stub_http_get(code: 401, body: 'Unauthorized')

      expect do
        client.count_schedule_pipelines_since(schedule_id: schedule_id, since_time: since_time)
      end.to raise_error(/GitLab API 401/)
    end

    it 'raises when the API returns a non-array body (e.g. an error envelope)' do
      stub_http_get(code: 200, body: Gitlab::Json.dump({ 'message' => '404 Not Found' }))

      expect do
        client.count_schedule_pipelines_since(schedule_id: schedule_id, since_time: since_time)
      end.to raise_error(/non-array/)
    end
  end
end
