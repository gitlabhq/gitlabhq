# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'

require_relative '../../../scripts/database/check_ci_partition_pruning'

RSpec.describe CheckCiPartitionPruning, feature_category: :tooling do
  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:tmpdir) { Dir.mktmpdir }

  subject(:gate) { described_class.new(tmpdir, logger) }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  def write_gz(name, lines)
    Zlib::GzipWriter.open(File.join(tmpdir, name)) { |gz| lines.each { |line| gz.puts(line) } }
  end

  def write_new_fingerprints(contents)
    File.write(File.join(tmpdir, 'new_query_fingerprints.txt'), contents)
  end

  describe '#run' do
    before do
      allow(gate.comment_poster).to receive(:post)
    end

    context 'when the new fingerprints match offenders in the artifacts' do
      before do
        write_gz('p_ci_pipelines_multiple_partition_scans.ndjson.gz', [
          { 'fingerprint' => 'fp1', 'job_name' => 'rspec a',
            'normalized' => "SELECT *\nFROM p_ci_pipelines\nWHERE id = $1" }.to_json,
          { 'fingerprint' => 'fp1', 'job_name' => 'rspec a',
            'normalized' => 'SELECT * FROM p_ci_pipelines WHERE id = $1' }.to_json # duplicate query
        ])
        write_gz('p_ci_builds_multiple_partition_scans.ndjson.gz', [
          '{"fingerprint":"fp1","job_name":"rspec a"}', # same query, also touches p_ci_builds
          '{"fingerprint":"fp2","job_name":"rspec c"}',
          '{"fingerprint":"fp_old","job_name":"rspec d"}' # not in the new set -> excluded
        ])
        write_gz('p_ci_corrupt_multiple_partition_scans.ndjson.gz', ['not valid json']) # tolerated
        write_new_fingerprints("fp1\nfp2\n")
      end

      it 'merges tables, dedups, filters to new fingerprints, tolerates corrupt files, and returns the count' do
        expect(gate.run).to eq(2)

        expect(gate.comment_poster).to have_received(:post).with(
          a_collection_containing_exactly(
            a_hash_including('fingerprint' => 'fp1',
              'tables' => contain_exactly('p_ci_pipelines', 'p_ci_builds')),
            a_hash_including('fingerprint' => 'fp2',
              'tables' => contain_exactly('p_ci_builds'))
          )
        )
      end
    end

    context 'when logging the plaintext report' do
      before do
        write_gz('p_ci_pipelines_multiple_partition_scans.ndjson.gz', [
          { 'fingerprint' => 'fp1', 'job_name' => 'rspec a',
            'normalized' => "SELECT *\nFROM p_ci_pipelines\nWHERE id = $1" }.to_json
        ])
        write_new_fingerprints("fp1\n")
      end

      it 'logs the offender fingerprint, tables, flattened SQL, resolution options, and coverage caveat' do
        gate.run

        expect(logger).to have_received(:info).with(
          satisfy do |msg|
            msg.include?('fp1') && msg.include?('p_ci_pipelines') &&
              msg.include?('first seen in `rspec a`') && # job name wrapped in backticks
              msg.include?('SELECT * FROM p_ci_pipelines WHERE id = $1') && # multi-line SQL flattened
              msg.match?(/-{10,}\nHow to resolve \(do one of the following\):/) && # separated from queries
              msg.include?('Fix the query') && msg.include?('Grant an exception') &&
              msg.include?('Bypass the check') && msg.include?('coverage may be partial') &&
              msg.end_with?('-' * 72) # trailing separator sets the report off from later logs
          end
        )
      end
    end

    context 'when reading the new-fingerprints file' do
      before do
        write_gz('p_ci_builds_multiple_partition_scans.ndjson.gz', [
          '{"fingerprint":"fp1","job_name":"rspec a"}',
          '{"fingerprint":"fp2","job_name":"rspec b"}'
        ])
      end

      {
        'with a trailing newline' => "fp1\nfp2\n",
        'without a trailing newline' => "fp1\nfp2",
        'with extra blank lines' => "fp1\nfp2\n\n"
      }.each do |description, contents|
        it "detects every new offender #{description}" do
          write_new_fingerprints(contents)

          expect(gate.run).to eq(2)
        end
      end
    end

    context 'when the new fingerprints match no offenders in the artifacts' do
      it 'returns 0, posts nothing, and logs that none were found' do
        write_gz('p_ci_builds_multiple_partition_scans.ndjson.gz', ['{"fingerprint":"fp1","job_name":"rspec a"}'])
        write_new_fingerprints("other\n")

        expect(gate.run).to eq(0)
        expect(gate.comment_poster).not_to have_received(:post)
        expect(logger).to have_received(:info).with('No new unpartitioned CI query offenders found')
      end
    end

    context 'when there are no offender artifacts to read' do
      it 'returns 0 and posts nothing' do
        write_new_fingerprints("fp1\n")

        expect(gate.run).to eq(0)
        expect(gate.comment_poster).not_to have_received(:post)
      end
    end

    # The corrupt artifact is a tripwire: if the check ever globbed the artifacts it would warn about
    # this file. Asserting the warn never fires proves the check exits before reading any artifacts.
    shared_examples 'skips the check without reading artifacts' do
      before do
        write_gz('p_ci_corrupt_multiple_partition_scans.ndjson.gz', ['not valid json'])
      end

      it 'returns 0, posts nothing, and does not read any artifacts' do
        expect(gate.run).to eq(0)
        expect(gate.comment_poster).not_to have_received(:post)
        expect(logger).to have_received(:info).with('No new fingerprints found, skipping check')
        expect(logger).not_to have_received(:warn).with(/partition scan artifact/)
      end
    end

    context 'when the new fingerprints file is empty' do
      before do
        write_new_fingerprints('')
      end

      it_behaves_like 'skips the check without reading artifacts'
    end

    context 'when the new fingerprints file contains only blank lines' do
      before do
        write_new_fingerprints("\n\n")
      end

      it_behaves_like 'skips the check without reading artifacts'
    end

    context 'when the new fingerprints file is absent' do
      it_behaves_like 'skips the check without reading artifacts'

      it 'logs that the merge request query differ did not run' do
        gate.run

        expect(logger).to have_received(:info).with(/query differ did not run/)
      end
    end

    context 'when the new fingerprints file cannot be read' do
      before do
        FileUtils.mkdir(File.join(tmpdir, 'new_query_fingerprints.txt')) # a directory can't be read as a file
      end

      it_behaves_like 'skips the check without reading artifacts'

      it 'warns that the file could not be read' do
        gate.run

        expect(logger).to have_received(:warn).with(/Could not read new_query_fingerprints/)
      end
    end
  end

  describe 'CommentPoster' do
    let(:poster) { gate.comment_poster }
    let(:marker) { poster.class::MARKER }
    let(:offender) do
      { 'tables' => ['p_ci_pipelines'], 'fingerprint' => 'fp1', 'job_name' => 'rspec unit',
        'normalized' => 'SELECT * FROM p_ci_pipelines WHERE id = $1' }
    end

    let(:offender2) do
      { 'tables' => ['p_ci_stages'], 'fingerprint' => 'fp2', 'job_name' => 'rspec unit',
        'normalized' => 'SELECT * FROM p_ci_stages WHERE id = $1' }
    end

    # A note we previously posted, carrying the hidden fingerprints line for the given offenders.
    def marker_note(offenders, id: 7)
      fps = offenders.map { |o| o['fingerprint'] }.sort.join(',')
      { 'id' => id, 'body' => "#{marker}\n<!-- fingerprints:#{fps} -->\n" }
    end

    def http_response(notes, next_page: '', status: :ok, retry_after: nil)
      klass, code = {
        ok: [Net::HTTPOK, '200'],
        created: [Net::HTTPCreated, '201'],
        forbidden: [Net::HTTPForbidden, '403'],
        too_many_requests: [Net::HTTPTooManyRequests, '429'],
        internal_server_error: [Net::HTTPInternalServerError, '500'],
        bad_gateway: [Net::HTTPBadGateway, '502'],
        service_unavailable: [Net::HTTPServiceUnavailable, '503'],
        gateway_timeout: [Net::HTTPGatewayTimeout, '504'],
        not_implemented: [Net::HTTPNotImplemented, '501']
      }.fetch(status)
      response = klass.new('1.1', code, code)
      allow(response).to receive(:body).and_return(notes.to_json)
      allow(response).to receive(:[]).with('x-next-page').and_return(next_page)
      allow(response).to receive(:[]).with('retry-after').and_return(retry_after)
      response
    end

    before do
      stub_const('API::DEFAULT_OPTIONS', {
        project: '278964',
        api_token: 'a-token',
        endpoint: 'https://gitlab.example.com/api/v4'
      })
      stub_const('Host::DEFAULT_OPTIONS', { mr_iid: '42' })
      allow(poster).to receive(:create_note)
      allow(poster).to receive(:sleep) # never actually block on backoff in the retry tests
    end

    it 'posts a comment for the offenders when nothing has been reported yet' do
      allow(poster).to receive(:all_notes).and_return([])

      poster.post([offender])

      expect(poster).to have_received(:create_note).with(/New unpartitioned CI queries detected/)
    end

    it 'posts nothing when there are no offenders' do
      allow(poster).to receive(:all_notes).and_return([])

      poster.post([])

      expect(poster).not_to have_received(:create_note)
    end

    it 'posts nothing when every offender was already reported' do
      allow(poster).to receive(:all_notes).and_return([marker_note([offender])])

      poster.post([offender])

      expect(poster).not_to have_received(:create_note)
    end

    it 'posts only the offenders not reported before' do
      allow(poster).to receive(:all_notes).and_return([marker_note([offender])])

      poster.post([offender, offender2]) # fp1 already reported; only fp2 is fresh

      expect(poster).to have_received(:create_note).with(
        satisfy do |body|
          body.include?('p_ci_stages') &&
            body.include?('fingerprints:fp2') &&
            body.index('p_ci_pipelines').nil?
        end
      )
    end

    it 'logs which offender fingerprints are already reported and which are fresh' do
      allow(poster).to receive(:all_notes).and_return([marker_note([offender])])

      poster.post([offender, offender2]) # fp1 already reported; fp2 is fresh

      expect(logger).to have_received(:info).with(/already reported in an earlier comment: fp1/)
      expect(logger).to have_received(:info).with(/not yet reported \(posting now\): fp2/)
    end

    it 'treats fingerprints reported across several notes as already known' do
      allow(poster).to receive(:all_notes)
        .and_return([marker_note([offender]), marker_note([offender2], id: 8)])

      poster.post([offender, offender2]) # both already reported, in different notes

      expect(poster).not_to have_received(:create_note)
    end

    it 'skips entirely (no API call) when the token is absent, e.g. on forks' do
      stub_const('API::DEFAULT_OPTIONS', API::DEFAULT_OPTIONS.merge(api_token: nil))
      forked_poster = poster.class.new(logger) # reads the token-less options at init
      allow(forked_poster).to receive(:all_notes)

      forked_poster.post([offender])

      expect(forked_poster).not_to have_received(:all_notes)
    end

    it 'logs and swallows API errors (with the exception class) instead of failing the check' do
      allow(poster).to receive(:all_notes).and_raise(Net::OpenTimeout, "boom")

      expect { poster.post([offender]) }.not_to raise_error
      expect(logger).to have_received(:warn).with(/Failed to post MR comment: boom \(Net::OpenTimeout\)/)
    end

    it 'escapes pipe characters so query text does not break the Markdown table' do
      allow(poster).to receive(:all_notes).and_return([])

      poster.post([offender.merge('normalized' => 'SELECT 1 || 2 FROM p_ci_pipelines')])

      expect(poster).to have_received(:create_note).with(include('SELECT 1 \\|\\| 2'))
    end

    it 'uses singular or plural wording based on the number of offenders', :aggregate_failures do
      allow(poster).to receive(:all_notes).and_return([])

      poster.post([offender])
      poster.post([offender, offender2])

      expect(poster).to have_received(:create_note).with(/query below scans/)
      expect(poster).to have_received(:create_note).with(/queries below scan /)
    end

    it 'truncates an over-long query preview in the summary row' do
      allow(poster).to receive(:all_notes).and_return([])

      poster.post([offender.merge('normalized' => "SELECT #{'a' * 200}")])

      expect(poster).to have_received(:create_note).with(include('...'))
    end

    context 'when inlining the full queries would push the comment past the note size limit' do
      let(:job_url) { 'https://gitlab.example.com/gitlab-org/gitlab/-/jobs/1' }
      let(:posted) { [] }

      # One offender whose query alone overflows the budget, so the fallback is the only way to post.
      let(:huge_offender) do
        offender.merge('normalized' => "SELECT #{'a' * poster.class::MAX_BODY_BYTESIZE}")
      end

      before do
        allow(poster).to receive_messages(all_notes: [], job_url: job_url)
        allow(poster).to receive(:create_note) { |body| posted << body }
      end

      it 'drops the collapsible and links the job log instead', :aggregate_failures do
        poster.post([huge_offender])

        expect(posted.last).to include("[job log](#{job_url})")
        expect(posted.last).not_to include('<details>')
      end

      it 'posts a body that fits within the limit' do
        poster.post([huge_offender])

        expect(posted.last.bytesize).to be <= poster.class::MAX_BODY_BYTESIZE
      end

      it 'still reports the offender in the summary table and the hidden fingerprints line' do
        poster.post([huge_offender])

        expect(posted.last).to include('<!-- fingerprints:fp1 -->', '| `fp1` |')
      end

      it 'logs that it linked the job log rather than inlining the queries' do
        poster.post([huge_offender])

        expect(logger).to have_received(:info).with(/linking to the job log instead/)
      end

      it 'keeps inlining the full queries when they do fit' do
        poster.post([offender])

        expect(posted.last).to include(
          '<details><summary>Full queries</summary>', 'SELECT * FROM p_ci_pipelines WHERE id = $1'
        )
      end
    end

    it 'reads reported fingerprints from notes spread across paginated responses' do
      allow(poster).to receive(:request).and_return(
        http_response([marker_note([offender])], next_page: '2'),
        http_response([marker_note([offender2], id: 8)], next_page: '')
      )

      poster.post([offender, offender2]) # fp1 is on page 1, fp2 on page 2; both already reported

      expect(poster).not_to have_received(:create_note)
    end

    it 'retries a rate-limited (429) request, waiting the Retry-After the server asks for' do
      allow(poster).to receive(:send_request).and_return(
        http_response([], status: :too_many_requests, retry_after: '3'),
        http_response([])
      )

      poster.post([offender])

      expect(poster).to have_received(:send_request).twice
      expect(poster).to have_received(:sleep).with(3)
    end

    it 'gives up after the retry limit, backing off exponentially when no Retry-After is given' do
      allow(poster).to receive(:send_request).and_return(http_response([], status: :too_many_requests))

      poster.post([offender])

      expect(poster).to have_received(:send_request).exactly(poster.class::MAX_RETRIES + 1).times
      expect(poster).to have_received(:sleep).with(2) # 2**1
      expect(poster).to have_received(:sleep).with(4) # 2**2
    end

    it 'caps the backoff at MAX_BACKOFF even when the server asks for a larger Retry-After' do
      allow(poster).to receive(:send_request).and_return(
        http_response([], status: :too_many_requests, retry_after: '600'),
        http_response([])
      )

      poster.post([offender])

      expect(poster).to have_received(:sleep).with(poster.class::MAX_BACKOFF)
    end

    # Each transient 5xx is retried on the idempotent GET (429 is covered separately, for any method).
    %i[internal_server_error bad_gateway service_unavailable gateway_timeout].each do |status|
      it "retries an idempotent GET on a transient #{status}" do
        allow(poster).to receive(:send_request).and_return(
          http_response([], status: status), # first GET attempt fails
          http_response([]) # retry succeeds
        )

        poster.post([offender])

        expect(poster).to have_received(:send_request).twice
      end
    end

    it 'does not retry a non-transient 5xx (e.g. 501 Not Implemented)' do
      allow(poster).to receive(:send_request).and_return(http_response({}, status: :not_implemented))

      poster.post([offender])

      expect(poster).to have_received(:send_request).once
      expect(poster).not_to have_received(:sleep)
      expect(logger).to have_received(:warn).with(/could not read existing MR notes.*HTTP 501/)
    end

    it 'does not retry a connection error; it bubbles up and the run gives up' do
      allow(poster).to receive(:send_request).and_raise(Net::OpenTimeout)

      poster.post([offender])

      expect(poster).to have_received(:send_request).once
      expect(poster).not_to have_received(:sleep)
      expect(logger).to have_received(:warn).with(/Failed to post MR comment/)
    end

    it 'does not retry the non-idempotent POST on a 5xx (avoids double-posting)' do
      allow(poster).to receive(:create_note).and_call_original
      allow(poster).to receive_messages(all_notes: [], send_request: http_response({}, status: :service_unavailable))

      poster.post([offender])

      expect(poster).to have_received(:send_request).once
      expect(poster).not_to have_received(:sleep)
      expect(logger).to have_received(:warn).with(/MR comment was not posted.*HTTP 503/)
    end

    it 'retries a rate-limited (429) POST -- the write was rejected, not applied, so it is safe' do
      allow(poster).to receive(:all_notes).and_return([])
      allow(poster).to receive(:create_note).and_call_original
      allow(poster).to receive(:send_request).and_return(
        http_response({}, status: :too_many_requests, retry_after: '1'), # first POST is rate-limited
        http_response({}, status: :created) # retry is accepted
      )

      poster.post([offender])

      expect(poster).to have_received(:send_request).twice
      expect(logger).to have_received(:info).with('Posted MR comment (HTTP 201)')
    end

    it 'aborts without posting when existing notes cannot be read' do
      allow(poster).to receive(:send_request)
        .and_return(http_response({ 'message' => '403 Forbidden' }, status: :forbidden))

      poster.post([offender])

      expect(logger).to have_received(:warn).with(/could not read existing MR notes.*HTTP 403/)
      expect(poster).not_to have_received(:create_note)
    end

    it 'logs a confirmation when the API accepts the comment' do
      allow(poster).to receive(:create_note).and_call_original
      allow(poster).to receive_messages(all_notes: [], request: http_response({}, status: :created))

      poster.post([offender])

      expect(logger).to have_received(:info).with('Posted MR comment (HTTP 201)')
    end

    it 'warns that the comment was not posted when the request comes back non-2xx' do
      # e.g. the retries were exhausted and the request still came back rate-limited (429).
      allow(poster).to receive(:create_note).and_call_original
      allow(poster).to receive_messages(
        all_notes: [],
        request: http_response({ 'message' => 'Too Many Requests' }, status: :too_many_requests)
      )

      poster.post([offender])

      expect(logger).to have_received(:warn).with(/MR comment was not posted.*HTTP 429/)
    end
  end
end
