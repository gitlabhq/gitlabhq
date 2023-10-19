# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'json'
require_relative '../../../scripts/pipeline/average_reports'

RSpec.describe AverageReports, feature_category: :tooling do
  let(:initial_report) do
    {
      'spec/frontend/fixtures/analytics.rb' => 1,
      'spec/frontend/fixtures/runner_instructions.rb' => 0.8074841039997409,
      'ee/spec/frontend/fixtures/analytics/value_streams_test_stage.rb' => 50.35115972699987,
      'ee/spec/frontend/fixtures/merge_requests.rb' => 19.16644390500005,
      'old' => 123
    }
  end

  let(:new_report) do
    {
      'spec/frontend/fixtures/analytics.rb' => 2,
      'spec/frontend/fixtures/runner_instructions.rb' => 0,
      'ee/spec/frontend/fixtures/analytics/value_streams_test_stage.rb' => 0,
      'ee/spec/frontend/fixtures/merge_requests.rb' => 0,
      'new' => 234
    }
  end

  let(:new_report_2) do
    {
      'spec/frontend/fixtures/analytics.rb' => 3,
      'new' => 468
    }
  end

  let(:initial_report_file) do
    Tempfile.new('temp_initial_report.json').tap do |f|
      # rubocop:disable Gitlab/Json
      f.write(JSON.dump(initial_report))
      # rubocop:enable Gitlab/Json
      f.close
    end
  end

  let(:new_report_file_1) do |_f|
    Tempfile.new('temp_new_report1.json').tap do |f|
      # rubocop:disable Gitlab/Json
      f.write(JSON.dump(new_report))
      # rubocop:enable Gitlab/Json
      f.close
    end
  end

  let(:new_report_file_2) do |_f|
    Tempfile.new('temp_new_report2.json').tap do |f|
      # rubocop:disable Gitlab/Json
      f.write(JSON.dump(new_report_2))
      # rubocop:enable Gitlab/Json
      f.close
    end
  end

  before do
    allow(subject).to receive(:puts)
  end

  after do
    initial_report_file.unlink
    new_report_file_1.unlink
    new_report_file_2.unlink
  end

  describe 'execute' do
    context 'with 1 new report' do
      subject do
        described_class.new(
          initial_report_file: initial_report_file.path,
          new_report_files: [new_report_file_1.path]
        )
      end

      it 'returns average durations' do
        results = subject.execute

        expect(results['spec/frontend/fixtures/analytics.rb']).to be_within(0.01).of(1.5)
        expect(results['spec/frontend/fixtures/runner_instructions.rb']).to be_within(0.01).of(0.4)
        expect(results['ee/spec/frontend/fixtures/analytics/value_streams_test_stage.rb']).to be_within(0.01).of(25.17)
        expect(results['ee/spec/frontend/fixtures/merge_requests.rb']).to be_within(0.01).of(9.58)
        expect(results['new']).to be_within(0.01).of(234)

        # excludes entry missing from the new report
        expect(results['old']).to be_nil
      end
    end

    context 'with 2 new reports' do
      subject do
        described_class.new(
          initial_report_file: initial_report_file.path,
          new_report_files: [new_report_file_1.path, new_report_file_2.path]
        )
      end

      it 'returns average durations' do
        results = subject.execute

        expect(subject).to have_received(:puts).with("Updating #{initial_report_file.path} with 2 new reports...")
        expect(subject).to have_received(:puts).with("Updated 5 data points from #{new_report_file_1.path}")
        expect(subject).to have_received(:puts).with("Updated 2 data points from #{new_report_file_2.path}")

        expect(results['spec/frontend/fixtures/analytics.rb']).to be_within(0.01).of(2)
        expect(results['new']).to be_within(0.01).of(351)

        # retains entry present in one of the new reports
        expect(results['spec/frontend/fixtures/runner_instructions.rb']).to be_within(0.01).of(0.4)
        expect(results['ee/spec/frontend/fixtures/analytics/value_streams_test_stage.rb']).to be_within(0.01).of(25.17)
        expect(results['ee/spec/frontend/fixtures/merge_requests.rb']).to be_within(0.01).of(9.58)

        # excludes entry missing from both of the new reports
        expect(results['old']).to be_nil
      end
    end

    context 'when some of the new report files do not exist' do
      subject do
        described_class.new(
          initial_report_file: initial_report_file.path,
          new_report_files: [new_report_file_1.path, 'file_does_not_exist.json']
        )
      end

      it 'ignores the nil file and only process 1 new report' do
        subject.execute

        expect(subject).to have_received(:puts).with("Updating #{initial_report_file.path} with 1 new reports...")
        expect(subject).to have_received(:puts).with("Updated 5 data points from #{new_report_file_1.path}")
      end
    end
  end
end
