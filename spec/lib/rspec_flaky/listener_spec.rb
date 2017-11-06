require 'spec_helper'

describe RspecFlaky::Listener, :aggregate_failures do
  let(:already_flaky_example_uid) { '6e869794f4cfd2badd93eb68719371d1' }
  let(:suite_flaky_example_report) do
    {
      already_flaky_example_uid => {
        example_id: 'spec/foo/bar_spec.rb:2',
        file: 'spec/foo/bar_spec.rb',
        line: 2,
        description: 'hello world',
        first_flaky_at: 1234,
        last_flaky_at: 4321,
        last_attempts_count: 3,
        flaky_reports: 1,
        last_flaky_job: nil
      }
    }
  end
  let(:already_flaky_example_attrs) do
    {
      id: 'spec/foo/bar_spec.rb:2',
      metadata: {
        file_path: 'spec/foo/bar_spec.rb',
        line_number: 2,
        full_description: 'hello world'
      },
      execution_result: double(status: 'passed', exception: nil)
    }
  end
  let(:already_flaky_example) { RspecFlaky::FlakyExample.new(suite_flaky_example_report[already_flaky_example_uid]) }
  let(:new_example_attrs) do
    {
      id: 'spec/foo/baz_spec.rb:3',
      metadata: {
        file_path: 'spec/foo/baz_spec.rb',
        line_number: 3,
        full_description: 'hello GitLab'
      },
      execution_result: double(status: 'passed', exception: nil)
    }
  end

  before do
    # Stub these env variables otherwise specs don't behave the same on the CI
    stub_env('CI_PROJECT_URL', nil)
    stub_env('CI_JOB_ID', nil)
    stub_env('SUITE_FLAKY_RSPEC_REPORT_PATH', nil)
  end

  describe '#initialize' do
    shared_examples 'a valid Listener instance' do
      let(:expected_suite_flaky_examples) { {} }

      it 'returns a valid Listener instance' do
        listener = described_class.new

        expect(listener.to_report(listener.suite_flaky_examples))
          .to eq(expected_suite_flaky_examples)
        expect(listener.flaky_examples).to eq({})
      end
    end

    context 'when no report file exists' do
      it_behaves_like 'a valid Listener instance'
    end

    context 'when a report file exists and set by SUITE_FLAKY_RSPEC_REPORT_PATH' do
      let(:report_file) do
        Tempfile.new(%w[rspec_flaky_report .json]).tap do |f|
          f.write(JSON.pretty_generate(suite_flaky_example_report))
          f.rewind
        end
      end

      before do
        stub_env('SUITE_FLAKY_RSPEC_REPORT_PATH', report_file.path)
      end

      after do
        report_file.close
        report_file.unlink
      end

      it_behaves_like 'a valid Listener instance' do
        let(:expected_suite_flaky_examples) { suite_flaky_example_report }
      end
    end
  end

  describe '#example_passed' do
    let(:rspec_example) { double(new_example_attrs) }
    let(:notification) { double(example: rspec_example) }
    let(:listener) { described_class.new(suite_flaky_example_report.to_json) }

    shared_examples 'a non-flaky example' do
      it 'does not change the flaky examples hash' do
        expect { listener.example_passed(notification) }
          .not_to change { listener.flaky_examples }
      end
    end

    shared_examples 'an existing flaky example' do
      let(:expected_flaky_example) do
        {
          example_id: 'spec/foo/bar_spec.rb:2',
          file: 'spec/foo/bar_spec.rb',
          line: 2,
          description: 'hello world',
          first_flaky_at: 1234,
          last_attempts_count: 2,
          flaky_reports: 2,
          last_flaky_job: nil
        }
      end

      it 'changes the flaky examples hash' do
        new_example = RspecFlaky::Example.new(rspec_example)

        now = Time.now
        Timecop.freeze(now) do
          expect { listener.example_passed(notification) }
            .to change { listener.flaky_examples[new_example.uid].to_h }
        end

        expect(listener.flaky_examples[new_example.uid].to_h)
          .to eq(expected_flaky_example.merge(last_flaky_at: now))
      end
    end

    shared_examples 'a new flaky example' do
      let(:expected_flaky_example) do
        {
          example_id: 'spec/foo/baz_spec.rb:3',
          file: 'spec/foo/baz_spec.rb',
          line: 3,
          description: 'hello GitLab',
          last_attempts_count: 2,
          flaky_reports: 1,
          last_flaky_job: nil
        }
      end

      it 'changes the all flaky examples hash' do
        new_example = RspecFlaky::Example.new(rspec_example)

        now = Time.now
        Timecop.freeze(now) do
          expect { listener.example_passed(notification) }
            .to change { listener.flaky_examples[new_example.uid].to_h }
        end

        expect(listener.flaky_examples[new_example.uid].to_h)
          .to eq(expected_flaky_example.merge(first_flaky_at: now, last_flaky_at: now))
      end
    end

    describe 'when the RSpec example does not respond to attempts' do
      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 1 attempt' do
      let(:rspec_example) { double(new_example_attrs.merge(attempts: 1)) }

      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 2 attempts' do
      let(:rspec_example) { double(new_example_attrs.merge(attempts: 2)) }

      it_behaves_like 'a new flaky example'

      context 'with an existing flaky example' do
        let(:rspec_example) { double(already_flaky_example_attrs.merge(attempts: 2)) }

        it_behaves_like 'an existing flaky example'
      end
    end
  end

  describe '#dump_summary' do
    let(:listener) { described_class.new(suite_flaky_example_report.to_json) }
    let(:new_flaky_rspec_example) { double(new_example_attrs.merge(attempts: 2)) }
    let(:already_flaky_rspec_example) { double(already_flaky_example_attrs.merge(attempts: 2)) }
    let(:notification_new_flaky_rspec_example) { double(example: new_flaky_rspec_example) }
    let(:notification_already_flaky_rspec_example) { double(example: already_flaky_rspec_example) }

    context 'when a report file path is set by FLAKY_RSPEC_REPORT_PATH' do
      let(:report_file_path) { Rails.root.join('tmp', 'rspec_flaky_report.json') }
      let(:new_report_file_path) { Rails.root.join('tmp', 'rspec_flaky_new_report.json') }

      before do
        stub_env('FLAKY_RSPEC_REPORT_PATH', report_file_path)
        stub_env('NEW_FLAKY_RSPEC_REPORT_PATH', new_report_file_path)
        FileUtils.rm(report_file_path) if File.exist?(report_file_path)
        FileUtils.rm(new_report_file_path) if File.exist?(new_report_file_path)
      end

      after do
        FileUtils.rm(report_file_path) if File.exist?(report_file_path)
        FileUtils.rm(new_report_file_path) if File.exist?(new_report_file_path)
      end

      context 'when FLAKY_RSPEC_GENERATE_REPORT == "false"' do
        before do
          stub_env('FLAKY_RSPEC_GENERATE_REPORT', 'false')
        end

        it 'does not write any report file' do
          listener.example_passed(notification_new_flaky_rspec_example)

          listener.dump_summary(nil)

          expect(File.exist?(report_file_path)).to be(false)
          expect(File.exist?(new_report_file_path)).to be(false)
        end
      end

      context 'when FLAKY_RSPEC_GENERATE_REPORT == "true"' do
        before do
          stub_env('FLAKY_RSPEC_GENERATE_REPORT', 'true')
        end

        around do |example|
          Timecop.freeze { example.run }
        end

        it 'writes the report files' do
          listener.example_passed(notification_new_flaky_rspec_example)
          listener.example_passed(notification_already_flaky_rspec_example)

          listener.dump_summary(nil)

          expect(File.exist?(report_file_path)).to be(true)
          expect(File.exist?(new_report_file_path)).to be(true)

          expect(File.read(report_file_path))
            .to eq(JSON.pretty_generate(listener.to_report(listener.flaky_examples)))

          new_example = RspecFlaky::Example.new(notification_new_flaky_rspec_example)
          new_flaky_example = RspecFlaky::FlakyExample.new(new_example)
          new_flaky_example.update_flakiness!

          expect(File.read(new_report_file_path))
            .to eq(JSON.pretty_generate(listener.to_report(new_example.uid => new_flaky_example)))
        end
      end
    end
  end

  describe '#to_report' do
    let(:listener) { described_class.new(suite_flaky_example_report.to_json) }

    it 'transforms the internal hash to a JSON-ready hash' do
      expect(listener.to_report(already_flaky_example_uid => already_flaky_example))
        .to match(hash_including(suite_flaky_example_report))
    end
  end
end
