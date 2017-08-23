require 'spec_helper'

describe RspecFlaky::Listener do
  let(:flaky_example_report) do
    {
      'abc123' => {
        example_id: 'spec/foo/bar_spec.rb:2',
        file: 'spec/foo/bar_spec.rb',
        line: 2,
        description: 'hello world',
        first_flaky_at: 1234,
        last_flaky_at: instance_of(Time),
        last_attempts_count: 2,
        flaky_reports: 1,
        last_flaky_job: nil
      }
    }
  end
  let(:example_attrs) do
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
  end

  describe '#initialize' do
    shared_examples 'a valid Listener instance' do
      let(:expected_all_flaky_examples) { {} }

      it 'returns a valid Listener instance' do
        listener = described_class.new

        expect(listener.to_report(listener.all_flaky_examples))
          .to match(hash_including(expected_all_flaky_examples))
        expect(listener.new_flaky_examples).to eq({})
      end
    end

    context 'when no report file exists' do
      it_behaves_like 'a valid Listener instance'
    end

    context 'when a report file exists and set by ALL_FLAKY_RSPEC_REPORT_PATH' do
      let(:report_file) do
        Tempfile.new(%w[rspec_flaky_report .json]).tap do |f|
          f.write(JSON.pretty_generate(flaky_example_report))
          f.rewind
        end
      end

      before do
        stub_env('ALL_FLAKY_RSPEC_REPORT_PATH', report_file.path)
      end

      after do
        report_file.close
        report_file.unlink
      end

      it_behaves_like 'a valid Listener instance' do
        let(:expected_all_flaky_examples) { flaky_example_report }
      end
    end
  end

  describe '#example_passed' do
    let(:rspec_example) { double(example_attrs) }
    let(:notification) { double(example: rspec_example) }

    shared_examples 'a non-flaky example' do
      it 'does not change the flaky examples hash' do
        expect { subject.example_passed(notification) }
          .not_to change { subject.all_flaky_examples }
      end
    end

    describe 'when the RSpec example does not respond to attempts' do
      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 1 attempt' do
      let(:rspec_example) { double(example_attrs.merge(attempts: 1)) }

      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 2 attempts' do
      let(:rspec_example) { double(example_attrs.merge(attempts: 2)) }
      let(:expected_new_flaky_example) do
        {
          example_id: 'spec/foo/baz_spec.rb:3',
          file: 'spec/foo/baz_spec.rb',
          line: 3,
          description: 'hello GitLab',
          first_flaky_at: instance_of(Time),
          last_flaky_at: instance_of(Time),
          last_attempts_count: 2,
          flaky_reports: 1,
          last_flaky_job: nil
        }
      end

      it 'does not change the flaky examples hash' do
        expect { subject.example_passed(notification) }
          .to change { subject.all_flaky_examples }

        new_example = RspecFlaky::Example.new(rspec_example)

        expect(subject.all_flaky_examples[new_example.uid].to_h)
          .to match(hash_including(expected_new_flaky_example))
      end
    end
  end

  describe '#dump_summary' do
    let(:rspec_example) { double(example_attrs) }
    let(:notification) { double(example: rspec_example) }

    context 'when a report file path is set by ALL_FLAKY_RSPEC_REPORT_PATH' do
      let(:report_file_path) { Rails.root.join('tmp', 'rspec_flaky_report.json') }

      before do
        stub_env('ALL_FLAKY_RSPEC_REPORT_PATH', report_file_path)
        FileUtils.rm(report_file_path) if File.exist?(report_file_path)
      end

      after do
        FileUtils.rm(report_file_path) if File.exist?(report_file_path)
      end

      context 'when FLAKY_RSPEC_GENERATE_REPORT == "false"' do
        before do
          stub_env('FLAKY_RSPEC_GENERATE_REPORT', 'false')
        end

        it 'does not write the report file' do
          subject.example_passed(notification)

          subject.dump_summary(nil)

          expect(File.exist?(report_file_path)).to be(false)
        end
      end

      context 'when FLAKY_RSPEC_GENERATE_REPORT == "true"' do
        before do
          stub_env('FLAKY_RSPEC_GENERATE_REPORT', 'true')
        end

        it 'writes the report file' do
          subject.example_passed(notification)

          subject.dump_summary(nil)

          expect(File.exist?(report_file_path)).to be(true)
        end
      end
    end
  end

  describe '#to_report' do
    it 'transforms the internal hash to a JSON-ready hash' do
      expect(subject.to_report('abc123' => RspecFlaky::FlakyExample.new(flaky_example_report['abc123'])))
        .to match(hash_including(flaky_example_report))
    end
  end
end
