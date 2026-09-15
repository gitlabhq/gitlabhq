# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/post_rspec_test_summary'

RSpec.describe 'post_rspec_test_summary', feature_category: :tooling do
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  let(:id_sequence) { (1..).each }

  # Build a minimal RSpec JSON example hash.
  #
  # Ids are unique per call unless one is passed: two reports share an id only
  # when the same example ran in more than one job.
  def rspec_example(file_path:, status: 'passed', run_time: 1.0, id: nil)
    {
      'file_path' => file_path,
      'status' => status,
      'run_time' => run_time,
      'id' => id || "#{file_path}[1:#{id_sequence.next}]",
      'description' => 'example'
    }
  end

  # Build a minimal RSpec JSON report hash.
  def rspec_report(examples)
    { 'examples' => examples }
  end

  # Make parse_report see a report with the given examples at path.
  def stub_report(path, examples)
    allow(File).to receive(:exist?).with(path).and_return(true)
    allow(File).to receive(:read).with(path).and_return(rspec_report(examples).to_json)
  end

  # ---------------------------------------------------------------------------
  # normalize_report_path
  # ---------------------------------------------------------------------------
  describe '#normalize_report_path' do
    it 'strips a leading ./ prefix' do
      expect(normalize_report_path('./spec/models/user_spec.rb')).to eq('spec/models/user_spec.rb')
    end

    it 'returns a path without ./ unchanged' do
      expect(normalize_report_path('spec/models/user_spec.rb')).to eq('spec/models/user_spec.rb')
    end

    it 'strips the CI_PROJECT_DIR prefix from absolute paths' do
      stub_env('CI_PROJECT_DIR', '/builds/gitlab-org/gitlab')

      result = normalize_report_path('/builds/gitlab-org/gitlab/spec/models/user_spec.rb')

      expect(result).to eq('spec/models/user_spec.rb')
    end

    it 'returns an empty string for nil' do
      expect(normalize_report_path(nil)).to eq('')
    end

    it 'returns an empty string for an empty string' do
      expect(normalize_report_path('')).to eq('')
    end
  end

  # ---------------------------------------------------------------------------
  # per_file_from_examples
  # ---------------------------------------------------------------------------
  describe '#per_file_from_examples' do
    it 'aggregates runtime and example count per file' do
      examples = [
        rspec_example(file_path: './spec/models/user_spec.rb', run_time: 1.5),
        rspec_example(file_path: './spec/models/user_spec.rb', run_time: 0.5),
        rspec_example(file_path: './spec/services/foo_spec.rb', run_time: 2.0)
      ]

      result = per_file_from_examples(examples)

      expect(result).to eq(
        'spec/models/user_spec.rb' => { runtime_s: 2.0, example_count: 2 },
        'spec/services/foo_spec.rb' => { runtime_s: 2.0, example_count: 1 }
      )
    end

    it 'returns an empty hash when there are no examples' do
      expect(per_file_from_examples([])).to eq({})
    end

    it 'skips examples with empty file_path' do
      expect(per_file_from_examples([rspec_example(file_path: '', run_time: 1.0)])).to eq({})
    end
  end

  # ---------------------------------------------------------------------------
  # reject_duplicate_examples
  # ---------------------------------------------------------------------------
  describe '#reject_duplicate_examples' do
    let(:report_example) { rspec_example(file_path: './spec/models/user_spec.rb') }

    it 'keeps the first run of an id and drops later ones' do
      retried = report_example.merge('status' => 'failed')

      expect(reject_duplicate_examples([report_example, retried], Set.new)).to eq([report_example])
    end

    it 'drops examples already recorded in the set' do
      seen = Set.new([report_example['id']])

      expect(reject_duplicate_examples([report_example], seen)).to eq([])
    end

    it 'keeps examples without an id rather than collapsing them' do
      without_id = report_example.except('id')

      expect(reject_duplicate_examples([without_id, without_id], Set.new)).to eq([without_id, without_id])
    end
  end

  # ---------------------------------------------------------------------------
  # parse_report
  # ---------------------------------------------------------------------------
  describe '#parse_report' do
    let(:report_path) { 'rspec/rspec-12345.json' }

    context 'when the file does not exist' do
      it 'returns nil' do
        expect(parse_report('/nonexistent/path.json')).to be_nil
      end
    end

    context 'when the file is valid JSON' do
      let(:examples) do
        [
          rspec_example(file_path: './spec/models/user_spec.rb', status: 'passed', run_time: 1.0),
          rspec_example(file_path: './spec/models/user_spec.rb', status: 'failed', run_time: 2.0),
          rspec_example(file_path: './spec/services/foo_spec.rb', status: 'pending', run_time: 0.0)
        ]
      end

      before do
        allow(File).to receive(:exist?).with(report_path).and_return(true)
        allow(File).to receive(:read).with(report_path).and_return(rspec_report(examples).to_json)
      end

      it 'counts the failures that drive the status emoji' do
        expect(parse_report(report_path)).to include(failed: 1)
      end

      it 'includes per_file breakdown' do
        result = parse_report(report_path)

        expect(result[:per_file]).to include(
          'spec/models/user_spec.rb' => { runtime_s: 3.0, example_count: 2 },
          'spec/services/foo_spec.rb' => { runtime_s: 0.0, example_count: 1 }
        )
      end
    end

    context 'when the report repeats an example id' do
      let(:duplicated) { rspec_example(file_path: './spec/models/user_spec.rb', run_time: 1.0) }

      before do
        allow(File).to receive(:exist?).with(report_path).and_return(true)
        allow(File).to receive(:read).with(report_path).and_return(
          rspec_report([duplicated, duplicated.merge('run_time' => 5.0)]).to_json
        )
      end

      it 'counts it once in the per-file breakdown' do
        result = parse_report(report_path)

        expect(result[:per_file]).to eq('spec/models/user_spec.rb' => { runtime_s: 1.0, example_count: 1 })
      end
    end

    context 'when the file contains invalid JSON' do
      before do
        allow(File).to receive(:exist?).with(report_path).and_return(true)
        allow(File).to receive(:read).with(report_path).and_return('not json')
      end

      it 'returns nil and warns' do
        expect { parse_report(report_path) }.to output(/Could not parse report/).to_stderr
        expect(parse_report(report_path)).to be_nil
      end
    end

    context 'when report_path is nil or empty' do
      it 'returns nil for nil' do
        expect(parse_report(nil)).to be_nil
      end

      it 'returns nil for empty string' do
        expect(parse_report('')).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # report_paths / parse_reports
  # ---------------------------------------------------------------------------
  describe '#report_paths' do
    it 'drops retry reports, which are already merged into the main report' do
      allow(Dir).to receive(:glob).with('rspec/rspec-*.json').and_return(
        %w[rspec/rspec-2.json rspec/rspec-retry-2.json rspec/rspec-1.json]
      )

      expect(report_paths('rspec/rspec-*.json')).to eq(%w[rspec/rspec-1.json rspec/rspec-2.json])
    end
  end

  describe '#parse_reports' do
    let(:job1) { 'rspec/rspec-1.json' }
    let(:job2) { 'rspec/rspec-2.json' }

    before do
      stub_report(job1, [
        rspec_example(file_path: './spec/models/user_spec.rb', status: 'passed', run_time: 1.0),
        rspec_example(file_path: './spec/models/user_spec.rb', status: 'failed', run_time: 2.0)
      ])
      stub_report(job2, [
        rspec_example(file_path: './spec/models/user_spec.rb', status: 'passed', run_time: 4.0),
        rspec_example(file_path: './spec/services/foo_spec.rb', status: 'pending', run_time: 0.5)
      ])
    end

    it 'sums per-file runtime and example counts across jobs' do
      result = parse_reports([job1, job2])

      expect(result[:per_file]).to eq(
        'spec/models/user_spec.rb' => { runtime_s: 7.0, example_count: 3 },
        'spec/services/foo_spec.rb' => { runtime_s: 0.5, example_count: 1 }
      )
    end

    it 'sums the failure count across jobs' do
      expect(parse_reports([job1, job2])).to include(failed: 1)
    end

    context 'when the same examples ran in two jobs' do
      # `rspec fail-fast` re-runs the spec files an MR changed and the predictive
      # jobs run them again, so both reports carry the same example ids.
      before do
        overlap = [
          rspec_example(file_path: './spec/scripts/foo_spec.rb', run_time: 3.0),
          rspec_example(file_path: './spec/scripts/foo_spec.rb', run_time: 1.0)
        ]

        stub_report(job1, overlap)
        stub_report(job2, overlap)
      end

      it 'counts each example once per file' do
        expect(parse_reports([job1, job2])[:per_file]).to eq(
          'spec/scripts/foo_spec.rb' => { runtime_s: 4.0, example_count: 2 }
        )
      end

      it 'counts each example once in the failure count' do
        expect(parse_reports([job1, job2])).to include(failed: 0)
      end
    end

    it 'ignores reports that could not be read' do
      allow(File).to receive(:exist?).with('rspec/missing.json').and_return(false)

      expect(parse_reports([job1, 'rspec/missing.json'])[:per_file]).to eq(
        'spec/models/user_spec.rb' => { runtime_s: 3.0, example_count: 2 }
      )
    end

    it 'returns nil when no report could be read' do
      allow(File).to receive(:exist?).with('rspec/missing.json').and_return(false)

      expect(parse_reports(['rspec/missing.json'])).to be_nil
      expect(parse_reports([])).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # write_baseline / per_file_from_baseline
  # ---------------------------------------------------------------------------
  describe '#write_baseline' do
    let(:baseline_path) { 'rspec/summary-baseline.json' }
    let(:stats) do
      { per_file: { 'spec/models/user_spec.rb' => { runtime_s: 3.0004, example_count: 2 } } }
    end

    it 'writes a compact per-file baseline' do
      expect(File).to receive(:write).with(
        baseline_path,
        { 'per_file' => { 'spec/models/user_spec.rb' => { 'runtime_s' => 3.0, 'example_count' => 2 } } }.to_json
      )

      expect { write_baseline(baseline_path, stats) }.to output(/Wrote baseline for 1 files/).to_stdout
    end

    it 'does nothing without a path' do
      expect(File).not_to receive(:write)

      write_baseline('', stats)
      write_baseline(nil, stats)
    end

    it 'does nothing when the report could not be parsed' do
      expect(File).not_to receive(:write)

      write_baseline(baseline_path, nil)
    end

    it 'warns instead of raising when the file cannot be written' do
      allow(File).to receive(:write).and_raise(Errno::EACCES)

      expect { write_baseline(baseline_path, stats) }.to output(/Could not write baseline/).to_stderr
    end
  end

  describe '#per_file_from_baseline' do
    it 'round-trips what write_baseline produces' do
      written = nil
      allow(File).to receive(:write) { |_path, contents| written = contents }
      allow($stdout).to receive(:puts)

      write_baseline('rspec/summary-baseline.json', {
        per_file: { 'spec/models/user_spec.rb' => { runtime_s: 3.0, example_count: 2 } }
      })

      # fast_spec_helper does not load Rails, so Gitlab::Json is unavailable here.
      expect(per_file_from_baseline(JSON.parse(written))).to eq( # rubocop:disable Gitlab/Json -- see above
        'spec/models/user_spec.rb' => { runtime_s: 3.0, example_count: 2 }
      )
    end

    it 'returns an empty hash when per_file is absent' do
      expect(per_file_from_baseline({})).to eq({})
    end
  end

  # ---------------------------------------------------------------------------
  # format_duration
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # Combined comment sections
  # ---------------------------------------------------------------------------
  describe '#splice_section' do
    let(:existing) do
      <<~MD
        <!-- test-result-summary -->

        ## Test Result Summary

        <!-- section:msw -->
        ### MSW Test Result Summary

        msw body
        <!-- /section:msw -->

        <!-- section:rspec -->
        ### RSpec Test Result Summary

        stale rspec body
        <!-- /section:rspec -->
      MD
    end

    it 'replaces only its own section' do
      result = splice_section(existing, 'rspec', "### RSpec Test Result Summary\n\nfresh rspec body")

      expect(result).to include('fresh rspec body')
      expect(result).not_to include('stale rspec body')
    end

    it 'leaves the other section untouched' do
      result = splice_section(existing, 'rspec', 'fresh rspec body')

      expect(result).to include("<!-- section:msw -->\n### MSW Test Result Summary\n\nmsw body\n<!-- /section:msw -->")
    end

    it 'appends the section when its markers are missing' do
      body = "<!-- test-result-summary -->\n\n<!-- section:msw -->\nmsw body\n<!-- /section:msw -->\n"

      result = splice_section(body, 'rspec', 'rspec body')

      expect(result).to include('<!-- section:rspec -->')
      expect(result).to include('rspec body')
      expect(result).to include('msw body')
    end
  end

  describe '#placeholder_section' do
    it 'reports a counterpart job that is in the pipeline as pending' do
      expect(placeholder_section('msw', job_present: true)).to include('Pending')
    end

    it 'reports a counterpart job absent from the pipeline as not run' do
      expect(placeholder_section('msw', job_present: false)).to include('Did not run')
    end
  end

  describe '#build_combined_comment' do
    it 'carries the shared marker and both sections' do
      comment = build_combined_comment('rspec', 'rspec body', counterpart_present: false)

      expect(comment).to include('<!-- test-result-summary -->')
      expect(comment).to include('## Test Result Summary')
      expect(comment).to include('<!-- section:rspec -->')
      expect(comment).to include('rspec body')
      expect(comment).to include('<!-- section:msw -->')
      expect(comment).to include('Did not run')
    end
  end

  # ---------------------------------------------------------------------------
  # fetch_knapsack_baseline
  # ---------------------------------------------------------------------------
  describe '#fetch_knapsack_baseline' do
    let(:knapsack_url) { 'https://gitlab-org.gitlab.io/gitlab/knapsack/report-master.json' }
    let(:knapsack_data) do
      {
        'spec/models/user_spec.rb' => 3.5,
        'spec/services/foo_spec.rb' => 12.0
      }.to_json
    end

    def stub_knapsack(body:, code: '200')
      response = instance_double(Net::HTTPSuccess, is_a?: code == '200', code: code, body: body)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(code == '200')
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it 'returns a per_file map keyed by spec path' do
      stub_knapsack(body: knapsack_data)

      result = fetch_knapsack_baseline(knapsack_url)

      expect(result[:per_file]).to eq(
        'spec/models/user_spec.rb' => { runtime_s: 3.5, example_count: nil },
        'spec/services/foo_spec.rb' => { runtime_s: 12.0, example_count: nil }
      )
    end

    it 'returns nil and prints a message when the request fails' do
      allow(Net::HTTP).to receive(:get_response).and_raise(SocketError, 'connection refused')

      expect do
        expect(fetch_knapsack_baseline(knapsack_url)).to be_nil
      end.to output(/Could not fetch knapsack baseline/).to_stdout
    end

    it 'returns nil for a non-200 response' do
      stub_knapsack(body: 'Not Found', code: '404')

      expect do
        expect(fetch_knapsack_baseline(knapsack_url)).to be_nil
      end.to output(/Could not fetch knapsack baseline/).to_stdout
    end

    it 'returns nil when url is blank' do
      expect(fetch_knapsack_baseline('')).to be_nil
      expect(fetch_knapsack_baseline(nil)).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # fetch_changed_spec_files
  # ---------------------------------------------------------------------------
  describe '#fetch_changed_spec_files' do
    def mr_diff(new_path:, old_path: nil, new_file: false, deleted_file: false, renamed_file: false)
      {
        'new_path' => new_path,
        'old_path' => old_path || new_path,
        'new_file' => new_file,
        'deleted_file' => deleted_file,
        'renamed_file' => renamed_file
      }
    end

    it 'keeps added, modified and deleted spec files and drops everything else' do
      allow(self).to receive(:api_request).and_return([
        mr_diff(new_path: 'spec/models/user_spec.rb'),
        mr_diff(new_path: 'spec/models/new_spec.rb', new_file: true),
        mr_diff(new_path: 'spec/models/gone_spec.rb', deleted_file: true),
        mr_diff(new_path: 'app/models/user.rb')
      ])

      result = fetch_changed_spec_files('1', '2')

      expect(result[:files]).to eq([
        { path: 'spec/models/user_spec.rb', is_new: false, is_deleted: false, old_path: 'spec/models/user_spec.rb' },
        { path: 'spec/models/new_spec.rb', is_new: true, is_deleted: false, old_path: 'spec/models/new_spec.rb' },
        { path: 'spec/models/gone_spec.rb', is_new: false, is_deleted: true, old_path: 'spec/models/gone_spec.rb' }
      ])
      expect(result[:truncated]).to be(false)
    end

    it 'looks a renamed file up under its old path' do
      allow(self).to receive(:api_request).and_return([
        mr_diff(new_path: 'spec/models/renamed_spec.rb', old_path: 'spec/models/old_spec.rb', renamed_file: true)
      ])

      expect(fetch_changed_spec_files('1', '2')[:files].first).to include(old_path: 'spec/models/old_spec.rb')
    end

    it 'flags truncation when the page cap is reached' do
      page = Array.new(DIFFS_PER_PAGE) { |i| mr_diff(new_path: "spec/models/user#{i}_spec.rb") }
      allow(self).to receive(:api_request).and_return(page)

      result = fetch_changed_spec_files('1', '2')

      expect(result[:truncated]).to be(true)
      expect(result[:files].size).to eq(DIFFS_PER_PAGE * MAX_DIFF_PAGES)
    end

    it 'warns and reports no changed files when the diffs endpoint fails' do
      allow(self).to receive(:api_request).and_raise(StandardError, 'boom')

      expect { expect(fetch_changed_spec_files('1', '2')).to eq(files: [], truncated: false) }
        .to output(/Could not fetch MR changed files/).to_stderr
    end
  end

  describe '#within_noise?' do
    # search_labels_spec.rb: +2s on a 39s system spec -- well inside run variance.
    it 'treats a small delta on a slow file as noise' do
      expect(within_noise?(2.0, 39.0)).to be(true)
    end

    it 'treats a delta above the relative floor as signal' do
      expect(within_noise?(5.0, 39.0)).to be(false)
    end

    it 'falls back to the absolute floor on a fast file' do
      expect(within_noise?(2.0, 5.0)).to be(true)
    end

    it 'reports a delta above the absolute floor on a fast file as signal' do
      expect(within_noise?(5.0, 5.0)).to be(false)
    end

    it 'treats a negative delta symmetrically' do
      expect(within_noise?(-2.0, 39.0)).to be(true)
    end

    it 'is not noise when the delta is unknown' do
      expect(within_noise?(nil, 39.0)).to be(false)
    end

    it 'uses the absolute floor when the master runtime is unknown' do
      expect(within_noise?(2.0, nil)).to be(true)
    end
  end

  describe '#format_duration' do
    using RSpec::Parameterized::TableSyntax

    where(:seconds, :expected) do
      nil     | '—'
      -1      | '—'
      0       | '0s'
      5       | '5s'
      59      | '59s'
      60      | '1m 0s'
      90      | '1m 30s'
      3599    | '59m 59s'
      3600    | '1h 0m 0s'
      3661    | '1h 1m 1s'
      215_142 | '59h 45m 42s'
    end

    with_them do
      it { expect(format_duration(seconds)).to eq(expected) }
    end
  end

  # ---------------------------------------------------------------------------
  # format_signed_duration
  # ---------------------------------------------------------------------------
  describe '#append_headline' do
    it 'reports removed examples when the MR deletes more than it adds' do
      lines = []
      actionable = { files: [{}, {}], added_examples: -14, added_runtime_s: -12.8 }

      append_headline(lines, actionable, true)

      expect(lines.first).to eq('**14 examples removed** across 2 files | **−13s vs master**')
    end

    it 'reports added examples' do
      lines = []
      actionable = { files: [{}], added_examples: 3, added_runtime_s: 30.0 }

      append_headline(lines, actionable, true)

      expect(lines.first).to eq('**+3 new examples** across 1 file | **+30s vs master**')
    end

    it 'reports an unchanged example count' do
      lines = []
      actionable = { files: [{}], added_examples: 0, added_runtime_s: 2.0 }

      append_headline(lines, actionable, true)

      expect(lines.first).to eq('Changed 1 spec file with no change in example count | **+2s vs master**')
    end
  end

  describe '#format_signed_duration' do
    using RSpec::Parameterized::TableSyntax

    where(:seconds, :expected) do
      nil    | '—'
      0      | '0s'
      -0.36  | '0s'
      0.4    | '0s'
      12     | '+12s'
      130    | '+2m 10s'
      -5     | '−5s'
      -90    | '−1m 30s'
    end

    with_them do
      it { expect(format_signed_duration(seconds)).to eq(expected) }
    end
  end

  # ---------------------------------------------------------------------------
  # compute_actionable
  # ---------------------------------------------------------------------------
  describe '#compute_actionable' do
    let(:report) do
      {
        per_file: {
          'spec/models/slow_spec.rb' => { runtime_s: 170.0, example_count: 9 },
          'spec/models/new_spec.rb' => { runtime_s: 12.0, example_count: 4 },
          'spec/models/renamed_spec.rb' => { runtime_s: 20.0, example_count: 5 },
          'spec/models/untouched_spec.rb' => { runtime_s: 99.0, example_count: 3 }
        }
      }
    end

    let(:baseline) do
      {
        per_file: {
          'spec/models/slow_spec.rb' => { runtime_s: 40.0, example_count: 8 },
          'spec/models/old_name_spec.rb' => { runtime_s: 18.0, example_count: 5 }
        }
      }
    end

    it 'diffs a modified file against its master baseline' do
      changed_files = [{ path: 'spec/models/slow_spec.rb', is_new: false, old_path: 'spec/models/slow_spec.rb' }]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

      expect(result[:added_examples]).to eq(1)
      expect(result[:added_runtime_s]).to eq(130.0)
      expect(result[:files].first).to include(master_examples: 8, current_examples: 9, delta_runtime_s: 130.0)
    end

    it 'treats a brand-new file as fully added cost' do
      changed_files = [{ path: 'spec/models/new_spec.rb', is_new: true, old_path: 'spec/models/new_spec.rb' }]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

      expect(result[:added_examples]).to eq(4)
      expect(result[:added_runtime_s]).to eq(12.0)
      expect(result[:files].first).to include(is_new: true, master_examples: nil, master_runtime_s: nil)
    end

    it 'looks up a renamed file under its old path' do
      changed_files = [{ path: 'spec/models/renamed_spec.rb', is_new: false, old_path: 'spec/models/old_name_spec.rb' }]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

      # 20s / 5 examples now vs 18s / 5 examples on master: +2s, 0 net-new examples.
      expect(result[:added_runtime_s]).to eq(2.0)
      expect(result[:added_examples]).to eq(0)
    end

    it 'ignores changed files that did not run in this job' do
      changed_files = [{
        path: 'spec/models/not_in_report_spec.rb',
        is_new: false,
        old_path: 'spec/models/not_in_report_spec.rb'
      }]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)
      expect(result[:files]).to be_empty
    end

    it 'aggregates across multiple files into a single per-example number' do
      changed_files = [
        { path: 'spec/models/slow_spec.rb', is_new: false, old_path: 'spec/models/slow_spec.rb' },
        { path: 'spec/models/new_spec.rb', is_new: true, old_path: 'spec/models/new_spec.rb' }
      ]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

      # (130 + 12)s added over (1 + 4) new examples = 28.4s/example.
      expect(result[:added_runtime_s]).to eq(142.0)
      expect(result[:added_examples]).to eq(5)
    end

    it 'handles nil report gracefully' do
      changed_files = [{ path: 'spec/models/slow_spec.rb', is_new: false, old_path: 'spec/models/slow_spec.rb' }]

      result = compute_actionable(changed_files: changed_files, report: nil, baseline: baseline)
      expect(result[:files]).to be_empty
    end

    it 'handles nil baseline gracefully' do
      changed_files = [{ path: 'spec/models/new_spec.rb', is_new: true, old_path: 'spec/models/new_spec.rb' }]

      result = compute_actionable(changed_files: changed_files, report: report, baseline: nil)

      # No baseline: master counts as 0, so all examples are "new".
      expect(result[:added_examples]).to eq(4)
      expect(result[:files].first[:is_new]).to be(true)
    end

    context 'when a file modified by the MR has no baseline row' do
      # spec/models/new_spec.rb ran in this job but is absent from the baseline.
      # The diff says it is not a new file, so the missing row means "unknown",
      # not "everything in it was added".
      let(:changed_files) do
        [{ path: 'spec/models/new_spec.rb', is_new: false, old_path: 'spec/models/new_spec.rb' }]
      end

      it 'does not tag the file as new' do
        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:files].first[:is_new]).to be(false)
      end

      it 'reports unknown deltas rather than diffing against zero' do
        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:files].first).to include(delta_examples: nil, delta_runtime_s: nil)
      end

      it 'excludes the file from the actionable totals' do
        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:added_examples]).to eq(0)
        expect(result[:added_runtime_s]).to eq(0.0)
      end
    end

    context 'when the MR deletes a spec file' do
      # A deleted file cannot run, so without the zero fill the time the MR
      # gives back would never reach the summary.
      let(:changed_files) do
        [{
          path: 'spec/models/old_name_spec.rb',
          is_new: false,
          is_deleted: true,
          old_path: 'spec/models/old_name_spec.rb'
        }]
      end

      it 'credits the whole master cost back' do
        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:added_runtime_s]).to eq(-18.0)
        expect(result[:added_examples]).to eq(-5)
      end

      it 'renders the file as running to zero' do
        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:files].first).to include(
          is_deleted: true, current_runtime_s: 0.0, current_examples: 0, master_examples: 5
        )
      end

      it 'skips a deleted file the baseline never knew about' do
        changed_files = [{
          path: 'spec/models/never_seen_spec.rb',
          is_new: false,
          is_deleted: true,
          old_path: 'spec/models/never_seen_spec.rb'
        }]

        result = compute_actionable(changed_files: changed_files, report: report, baseline: baseline)

        expect(result[:files]).to be_empty
      end
    end
  end

  # ---------------------------------------------------------------------------
  # build_comment
  # ---------------------------------------------------------------------------
  describe '#build_comment' do
    let(:stats) { { failed: 0, per_file: {} } }

    let(:baseline) do
      { per_file: { 'spec/models/user_spec.rb' => { runtime_s: 40.0, example_count: 8 } } }
    end

    let(:base_args) do
      {
        job_name: 'rspec unit pg17 1/44',
        job_url: 'https://example.com/job/1',
        stats: stats,
        baseline: baseline
      }
    end

    it 'renders a sub-threshold delta as within noise' do
      actionable = {
        files: [{
          path: 'spec/features/projects/labels/search_labels_spec.rb',
          is_new: false,
          current_runtime_s: 41.0,
          master_runtime_s: 39.0,
          delta_runtime_s: 2.0,
          current_examples: 4,
          master_examples: 6,
          delta_examples: -2
        }],
        added_runtime_s: 2.0,
        added_examples: -2
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('| 39s -> 41s | within noise |')
    end

    it 'renders an unknown runtime delta as an em dash and omits the new tag' do
      actionable = {
        files: [{
          path: 'spec/features/projects/labels/search_labels_spec.rb',
          is_new: false,
          current_runtime_s: 35.0,
          master_runtime_s: nil,
          delta_runtime_s: nil,
          current_examples: 6,
          master_examples: nil,
          delta_examples: nil
        }],
        added_runtime_s: 0.0,
        added_examples: 0
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include(
        '| `spec/features/projects/labels/search_labels_spec.rb` | — -> 35s | — |'
      )
      expect(comment).not_to include('search_labels_spec.rb` (new)')
    end

    it 'renders a section body, leaving the shared marker to the combined comment' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to start_with('### RSpec Test Result Summary')
      expect(comment).not_to include(COMBINED_MARKER)
    end

    it 'reports the added cost without a budget verdict' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: false,
          current_runtime_s: 170.0,
          master_runtime_s: 40.0,
          delta_runtime_s: 130.0,
          current_examples: 9,
          master_examples: 8,
          delta_examples: 1
        }],
        added_runtime_s: 130.0,
        added_examples: 1
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('+1 new example')
      expect(comment).to include('+2m 10s vs master')
      expect(comment).to include('40s -> 2m 50s')
    end

    it 'never renders a budget verdict, however costly the change' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: true,
          current_runtime_s: 600.0,
          master_runtime_s: nil,
          delta_runtime_s: 600.0,
          current_examples: 1,
          master_examples: nil,
          delta_examples: 1
        }],
        added_runtime_s: 600.0,
        added_examples: 1
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).not_to include('Action required')
      expect(comment).not_to include('budget')
      expect(comment).not_to include('s/example')
    end

    it 'omits the per-new-example column from the per-file table' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: true,
          current_runtime_s: 60.0,
          master_runtime_s: nil,
          delta_runtime_s: 60.0,
          current_examples: 2,
          master_examples: nil,
          delta_examples: 2
        }],
        added_runtime_s: 60.0,
        added_examples: 2
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('| File | Runtime (master -> now) | Delta Runtime |')
      expect(comment).not_to include('Per new example')
    end

    it 'omits the delta and badge when no master baseline is available' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, baseline: nil, actionable: actionable)

      expect(comment).to include('No master baseline available yet')
      expect(comment).not_to include('Action required')
      expect(comment).not_to include('Warning')
      expect(comment).to include('**rspec unit pg17 1/44**: ✅ [job log]')
    end

    it 'reports missing report gracefully' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, stats: nil, actionable: actionable)

      expect(comment).to include('no JSON report found')
    end

    it 'renders a truncation warning when the diffs page cap is hit' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, actionable: actionable, truncated: true)

      expect(comment).to include('⚠️ **Warning**: This MR changes 500+ files')
      expect(comment).to include('the per-file breakdown is truncated')
    end

    it 'omits the truncation warning when the breakdown is complete' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, actionable: actionable, truncated: false)

      expect(comment).not_to include('per-file breakdown is truncated')
    end

    it 'shows "no changed RSpec spec files" when no changed files ran' do
      actionable = { files: [], added_runtime_s: 0.0, added_examples: 0 }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('No changed RSpec spec files detected in this MR.')
    end

    it 'shows changed files with no example-count change when delta_examples is zero' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: false,
          current_runtime_s: 45.0,
          master_runtime_s: 40.0,
          delta_runtime_s: 5.0,
          current_examples: 8,
          master_examples: 8,
          delta_examples: 0
        }],
        added_runtime_s: 5.0,
        added_examples: 0
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('with no change in example count')
    end

    it 'tags a deleted file and shows its cost coming back' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: false,
          is_deleted: true,
          current_runtime_s: 0.0,
          master_runtime_s: 40.0,
          delta_runtime_s: -40.0,
          current_examples: 0,
          master_examples: 8,
          delta_examples: -8
        }],
        added_runtime_s: -40.0,
        added_examples: -8
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('`spec/models/user_spec.rb` (deleted)')
      expect(comment).to include('| 40s -> 0s | −40s |')
    end

    it 'includes the per-file breakdown table when files are present' do
      actionable = {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: false,
          current_runtime_s: 50.0,
          master_runtime_s: 40.0,
          delta_runtime_s: 10.0,
          current_examples: 9,
          master_examples: 8,
          delta_examples: 1
        }],
        added_runtime_s: 10.0,
        added_examples: 1
      }

      comment = build_comment(**base_args, actionable: actionable)

      expect(comment).to include('<details><summary>Per-file breakdown</summary>')
      expect(comment).to include('`spec/models/user_spec.rb`')
      expect(comment).to include('| 40s -> 50s | +10s |')
    end
  end

  # ---------------------------------------------------------------------------
  # api_request
  # ---------------------------------------------------------------------------
  describe '#api_request' do
    let(:http) { instance_double(Net::HTTP) }

    # A real response subclass, so `is_a?(Net::HTTPSuccess)` answers honestly.
    def http_response(code, body)
      response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code.to_s).new('1.1', code.to_s, 'message')
      allow(response).to receive(:body).and_return(body)
      response
    end

    before do
      stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', 'token')
      stub_env('CI_API_V4_URL', 'https://gitlab.example.com/api/v4')
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(self).to receive(:sleep_seconds)
    end

    it 'sends the private token and parses the response body' do
      request = nil
      allow(http).to receive(:request) do |req|
        request = req
        http_response(200, '{"id":7}')
      end

      expect(api_request('GET', '/user')).to eq('id' => 7)
      expect(request['PRIVATE-TOKEN']).to eq('token')
      expect(request.uri.to_s).to eq('https://gitlab.example.com/api/v4/user')
    end

    it 'sends the request body as JSON' do
      request = nil
      allow(http).to receive(:request) do |req|
        request = req
        http_response(201, '{}')
      end

      api_request('POST', '/notes', { body: 'hello' })

      expect(request).to be_a(Net::HTTP::Post)
      expect(request.body).to eq('{"body":"hello"}')
    end

    it 'raises on an unsupported HTTP method' do
      expect { api_request('DELETE', '/user') }.to raise_error(ArgumentError, /Unsupported HTTP method/)
    end

    it 'retries a 500 and returns the retried response' do
      allow(http).to receive(:request).and_return(http_response(500, 'boom'), http_response(200, '{"ok":true}'))

      expect { expect(api_request('GET', '/user')).to eq('ok' => true) }.to output(/retrying in 2s/).to_stderr
    end

    it 'gives up after MAX_API_ATTEMPTS attempts' do
      allow(http).to receive(:request).and_return(http_response(500, 'boom'))

      expect { expect { api_request('GET', '/user') }.to raise_error(/GitLab API 500/) }.to output.to_stderr
      expect(http).to have_received(:request).exactly(MAX_API_ATTEMPTS).times
    end

    it 'does not retry a 403' do
      allow(http).to receive(:request).and_return(http_response(403, 'forbidden'))

      expect { api_request('GET', '/user') }.to raise_error(/GitLab API 403/)
      expect(http).to have_received(:request).once
    end

    it 'retries a network error' do
      attempts = 0
      allow(http).to receive(:request) do
        attempts += 1
        raise Errno::ECONNRESET if attempts == 1

        http_response(200, '{"ok":true}')
      end

      expect { expect(api_request('GET', '/user')).to eq('ok' => true) }.to output(/Network error/).to_stderr
    end
  end

  # ---------------------------------------------------------------------------
  # find_existing_note / counterpart_job_present?
  # ---------------------------------------------------------------------------
  describe '#find_existing_note' do
    let(:marker_note) { { 'id' => 9, 'body' => "#{COMBINED_MARKER}\nbody", 'author' => { 'username' => 'bot' } } }

    def stub_notes(notes)
      allow(self).to receive(:api_request).with('GET', a_string_including('/notes')).and_return(notes)
    end

    before do
      allow(self).to receive(:api_request).with('GET', '/user').and_return({ 'username' => 'bot' })
    end

    it 'returns the marked note written by the current user' do
      stub_notes([marker_note])

      expect(find_existing_note('1', '2')).to eq(marker_note)
    end

    it 'ignores a marked note written by somebody else' do
      stub_notes([marker_note.merge('author' => { 'username' => 'someone-else' })])

      expect(find_existing_note('1', '2')).to be_nil
    end

    it 'returns nil when no note carries the marker' do
      stub_notes([{ 'id' => 1, 'body' => 'unrelated', 'author' => { 'username' => 'bot' } }])

      expect(find_existing_note('1', '2')).to be_nil
    end

    it 'matches on the marker alone when the current user cannot be resolved' do
      allow(self).to receive(:api_request).with('GET', '/user').and_raise(StandardError, 'no token scope')
      stub_notes([marker_note])

      expect { expect(find_existing_note('1', '2')).to eq(marker_note) }
        .to output(/Could not resolve current user/).to_stderr
    end

    it 'warns and returns nil when the notes endpoint fails' do
      allow(self).to receive(:api_request).with('GET', a_string_including('/notes')).and_raise(StandardError, 'boom')

      expect { expect(find_existing_note('1', '2')).to be_nil }
        .to output(/Could not search for existing note/).to_stderr
    end
  end

  describe '#counterpart_job_present?' do
    before do
      stub_env('CI_PIPELINE_ID', '77')
    end

    it 'is true when the pipeline holds the job' do
      allow(self).to receive(:api_request).and_return([{ 'name' => 'jest-msw-integration' }])

      expect(counterpart_job_present?('1', 'jest-msw-integration')).to be(true)
    end

    it 'is false when the pipeline does not hold the job' do
      allow(self).to receive(:api_request).and_return([{ 'name' => 'rspec:test-summary' }])

      expect(counterpart_job_present?('1', 'jest-msw-integration')).to be(false)
    end

    it 'is false outside a pipeline' do
      stub_env('CI_PIPELINE_ID', '')

      expect(counterpart_job_present?('1', 'jest-msw-integration')).to be(false)
    end

    it 'warns and is false when the jobs endpoint fails' do
      allow(self).to receive(:api_request).and_raise(StandardError, 'boom')

      expect { expect(counterpart_job_present?('1', 'jest-msw-integration')).to be(false) }
        .to output(/Could not look up jest-msw-integration/).to_stderr
    end
  end

  # ---------------------------------------------------------------------------
  # post_or_update_comment
  # ---------------------------------------------------------------------------
  describe '#post_or_update_comment' do
    let(:section) { "### RSpec Test Result Summary\n\nfresh rspec body" }
    let(:calls) { [] }

    def record_api_calls(&raise_on)
      allow(self).to receive(:api_request) do |method, path, payload|
        calls << { method: method, path: path, payload: payload }
        raise_on&.call(method)
      end
    end

    context 'when no summary note exists yet' do
      before do
        allow(self).to receive_messages(find_existing_note: nil, counterpart_job_present?: true)
      end

      it 'posts a combined note holding this section and a placeholder for MSW' do
        record_api_calls

        expect { post_or_update_comment('1', '2', section) }
          .to output(/Posted new test summary comment/).to_stdout

        expect(calls.first[:method]).to eq('POST')
        expect(calls.first[:path]).to eq('/projects/1/merge_requests/2/notes')
        expect(calls.first[:payload][:body]).to include(COMBINED_MARKER, 'fresh rspec body', 'Pending')
      end
    end

    context 'when a summary note exists' do
      let(:existing_body) do
        "#{COMBINED_MARKER}\n\n<!-- section:rspec -->\nstale rspec body\n<!-- /section:rspec -->\n"
      end

      before do
        allow(self).to receive(:find_existing_note).and_return({ 'id' => 42, 'body' => existing_body })
      end

      it 'updates only its own section of that note' do
        record_api_calls

        expect { post_or_update_comment('1', '2', section) }
          .to output(/Updated the RSpec section/).to_stdout

        expect(calls.map { |c| c[:method] }).to eq(['PUT'])
        expect(calls.first[:path]).to eq('/projects/1/merge_requests/2/notes/42')
        expect(calls.first[:payload][:body]).to include('fresh rspec body')
        expect(calls.first[:payload][:body]).not_to include('stale rspec body')
      end

      it 'posts a new comment when the note cannot be updated' do
        record_api_calls { |method| raise StandardError, 'note is locked' if method == 'PUT' }

        expect { post_or_update_comment('1', '2', section) }
          .to output(/Posted new test summary comment/).to_stdout
          .and output(/Could not update note 42/).to_stderr

        expect(calls.map { |c| c[:method] }).to eq(%w[PUT POST])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # run / run_safely
  # ---------------------------------------------------------------------------
  describe '#run' do
    let(:argv) { ['--job-name', 'rspec:test-summary', '--report-path', 'rspec/rspec-1.json'] }
    let(:knapsack) { { per_file: { 'spec/models/user_spec.rb' => { runtime_s: 1.0, example_count: nil } } } }
    let(:changed) do
      {
        files: [{
          path: 'spec/models/user_spec.rb',
          is_new: false,
          is_deleted: false,
          old_path: 'spec/models/user_spec.rb'
        }],
        truncated: false
      }
    end

    before do
      stub_env('CI_MERGE_REQUEST_IID', '2')
      stub_env('CI_PROJECT_ID', '1')
      stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', 'token')
      stub_report('rspec/rspec-1.json', [rspec_example(file_path: './spec/models/user_spec.rb', run_time: 40.0)])

      allow(self).to receive_messages(fetch_knapsack_baseline: knapsack, fetch_changed_spec_files: changed)
    end

    it 'posts the rendered summary section' do
      expect(self).to receive(:post_or_update_comment)
        .with('1', '2', a_string_including('### RSpec Test Result Summary'))

      expect { run(argv) }.to output(/New examples/).to_stdout
    end

    it 'prints the comment without posting it on a dry run' do
      expect(self).not_to receive(:post_or_update_comment)

      expect { run(argv + ['--dry-run']) }.to output(/--dry-run: comment NOT posted/).to_stdout
    end

    it 'skips the comment outside a merge-request pipeline' do
      stub_env('CI_MERGE_REQUEST_IID', '')
      expect(self).not_to receive(:post_or_update_comment)

      expect { run(argv) }.to output(/Not a merge-request pipeline/).to_stdout
    end

    it 'skips the comment when the API token is missing' do
      stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', '')
      expect(self).not_to receive(:post_or_update_comment)

      expect { run(argv) }.to output(/cannot post comment/).to_stderr
    end

    it 'publishes the baseline on a master pipeline, which has no MR to comment on' do
      stub_env('CI_MERGE_REQUEST_IID', '')
      expect(self).to receive(:write_baseline).with('rspec/baseline.json', hash_including(:per_file))

      expect { run(argv + ['--baseline-path', 'rspec/baseline.json']) }.to output.to_stdout
    end
  end

  describe '#run_safely' do
    it 'warns instead of raising when the API fails, so a failed comment cannot fail the job' do
      allow(self).to receive(:run)
        .and_raise(RuntimeError, 'GitLab API 403 on POST /projects/1/merge_requests/1/notes: forbidden')

      expect { run_safely }.to output(/Test summary skipped: RuntimeError: GitLab API 403/).to_stderr
    end

    it 'passes its arguments through to run' do
      expect(self).to receive(:run).with(%w[--dry-run])

      run_safely(%w[--dry-run])
    end
  end
end
