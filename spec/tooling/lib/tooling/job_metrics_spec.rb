# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'time'

require_relative '../../../../tooling/lib/tooling/job_metrics'

RSpec.describe Tooling::JobMetrics, feature_category: :tooling do
  include StubENV

  attr_accessor :job_metrics_file, :job_metrics_file_path

  around do |example|
    self.job_metrics_file       = Tempfile.new('test-folder/job-metrics.json')
    self.job_metrics_file_path  = job_metrics_file.path

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      job_metrics_file.close
      job_metrics_file.unlink
    end
  end

  let(:instance)            { described_class.new(metrics_file_path: job_metrics_file_path) }
  let(:pipeline_created_at) { '2023-05-03T12:35:39.932Z' }

  before do
    stub_env(
      'CI_JOB_ID' => '1234',
      'CI_JOB_NAME' => 'rspec unit pg14 1/24',
      'CI_JOB_STAGE' => 'test',
      'CI_JOB_STARTED_AT' => (Time.now - 3600).iso8601, # 1h ago
      'CI_JOB_STATUS' => 'success',
      'CI_MERGE_REQUEST_IID' => '23412',
      'CI_PIPELINE_CREATED_AT' => pipeline_created_at,
      'CI_PIPELINE_ID' => '3393923023',
      'CI_PROJECT_ID' => '7489',
      'CI_SERVER_HOST' => 'localhost:300',
      'JOB_METRICS_FILE_PATH' => job_metrics_file_path
    )
  end

  describe '#initialize' do
    context 'when a path is given' do
      subject { described_class.new(metrics_file_path: job_metrics_file_path) }

      it 'instantiates the object' do
        expect(subject).to be_a(described_class)
      end

      it 'sets the correct path for the metrics file' do
        expect(subject.metrics_file_path).to eq(job_metrics_file_path)
      end
    end

    context 'when a path is not given' do
      subject { described_class.new }

      context 'when the JOB_METRICS_FILE_PATH env variable is set' do
        before do
          stub_env(
            'JOB_METRICS_FILE_PATH' => job_metrics_file_path
          )
        end

        it 'instantiates the object' do
          expect(subject).to be_a(described_class)
        end

        it 'sets the correct path for the metrics file' do
          expect(subject.metrics_file_path).to eq(ENV['JOB_METRICS_FILE_PATH'])
        end
      end

      context 'when the JOB_METRICS_FILE_PATH env variable is not set' do
        before do
          stub_env(
            'JOB_METRICS_FILE_PATH' => nil
          )
        end

        it 'raises an error' do
          expect { subject }.to raise_error('Please specify a path for the job metrics file.')
        end
      end
    end
  end

  describe '#create_metrics_file' do
    subject { instance.create_metrics_file }

    context 'when a valid metrics file exists' do
      before do
        allow(instance).to receive(:warn)
        allow(instance).to receive(:valid_metrics_file?).and_return(true)
      end

      it 'prints a message to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "A valid job metrics file already exists. We're not going to overwrite it.\n"
        ).to_stderr
      end

      it 'does not overwrite the existing metrics file' do
        expect(instance).not_to receive(:persist_metrics_file)

        subject
      end
    end

    context 'when a valid metrics file does not exist' do
      before do
        allow(instance).to receive(:valid_metrics_file?).and_return(false)
      end

      it 'persists the metrics file' do
        expect(instance).to receive(:persist_metrics_file).with(instance.default_metrics)

        subject
      end
    end
  end

  describe '#update_field' do
    subject { instance.update_field(field_name, field_value) }

    let(:field_name) { instance.default_fields.each_key.first }
    let(:field_value) { 'test_value' }

    context 'when the field to update is not in the default fields list' do
      let(:field_name) { 'not-in-default-list' }

      before do
        allow(instance).to receive(:warn)
      end

      it 'returns a warning to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "[job-metrics] ERROR: Could not update field #{field_name}, as it is not part of the allowed fields.\n"
        ).to_stderr
      end

      it 'does not write to the metrics file' do
        expect(instance).not_to receive(:persist_metrics_file)

        subject
      end
    end

    context 'when the field to update is in the default fields list' do
      it 'calls the update_file method with the correct arguments' do
        expect(instance).to receive(:update_file).with(field_name, field_value, type: :field)

        subject
      end
    end
  end

  describe '#update_tag' do
    subject { instance.update_tag(tag_name, tag_value) }

    let(:tag_name) { instance.default_tags.each_key.first }
    let(:tag_value) { 'test_value' }

    context 'when the tag to update is not in the default tags list' do
      let(:tag_name) { 'not-in-default-list' }

      before do
        allow(instance).to receive(:warn)
      end

      it 'returns a warning to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "[job-metrics] ERROR: Could not update tag #{tag_name}, as it is not part of the allowed tags.\n"
        ).to_stderr
      end

      it 'does not write to the metrics file' do
        expect(instance).not_to receive(:persist_metrics_file)

        subject
      end
    end

    context 'when the tag to update is in the default tags list' do
      it 'calls the update_file method with the correct arguments' do
        expect(instance).to receive(:update_file).with(tag_name, tag_value, type: :tag)

        subject
      end
    end
  end

  describe '#update_file' do
    subject { instance.update_file(tag_name, tag_value, type: type) }

    let(:type)      { :tag }
    let(:tag_name)  { instance.default_tags.each_key.first }
    let(:tag_value) { 'test_value' }

    context 'when the metrics file is not valid' do
      before do
        allow(instance).to receive(:valid_metrics_file?).and_return(false)
        allow(instance).to receive(:warn)
      end

      it 'returns a warning to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "[job-metrics] ERROR: Invalid job metrics file.\n"
        ).to_stderr
      end

      it 'does not write to the metrics file' do
        expect(instance).not_to receive(:persist_metrics_file)

        subject
      end
    end

    context 'when the metrics file is valid' do
      let(:metrics_hash) do
        {
          name: 'job-metrics',
          time: ENV['CI_PIPELINE_CREATED_AT'].to_time,
          tags: tags_hash,
          fields: fields_hash
        }
      end

      let(:tags_hash)   { instance.default_tags }
      let(:fields_hash) { instance.default_fields }

      before do
        allow(instance).to receive(:valid_metrics_file?).and_return(true)
        allow(instance).to receive(:load_metrics_file).and_return(metrics_hash)
      end

      context 'when updating a tag' do
        let(:type) { :tag }

        it 'updates the tag value' do
          expect(instance).to receive(:persist_metrics_file).with(
            hash_including(
              tags: hash_including(tag_name)
            )
          )

          subject
        end
      end

      context 'when updating a field' do
        let(:type) { :field }

        let(:field_name)  { instance.default_fields.each_key.first }
        let(:field_value) { 'test_value' }

        it 'updates the field value' do
          expect(instance).to receive(:persist_metrics_file).with(
            hash_including(
              fields: hash_including(field_name)
            )
          )

          subject
        end
      end
    end
  end

  describe '#push_metrics' do
    subject { instance.push_metrics }

    context 'when the metrics file is not valid' do
      before do
        allow(instance).to receive(:valid_metrics_file?).and_return(false)
        allow(instance).to receive(:warn)
      end

      it 'returns a warning to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "[job-metrics] ERROR: Invalid job metrics file. We will not push the metrics to InfluxDB\n"
        ).to_stderr
      end

      it 'does not write to the metrics file' do
        expect(instance).not_to receive(:persist_metrics_file)

        subject
      end
    end

    context 'when the metrics file is valid' do
      let(:metrics_hash) do
        {
          name: 'job-metrics',
          time: ENV['CI_PIPELINE_CREATED_AT'].to_time,
          tags: tags_hash,
          fields: fields_hash
        }
      end

      let(:tags_hash)   { instance.default_tags }
      let(:fields_hash) { instance.default_fields }
      let(:influx_write_api) { double('influx_write_api') } # rubocop:disable RSpec:VerifiedDoubles

      before do
        allow(instance).to receive(:influx_write_api).and_return(influx_write_api)
        allow(instance).to receive(:valid_metrics_file?).and_return(true)
        allow(instance).to receive(:load_metrics_file).and_return(metrics_hash)
        allow(instance).to receive(:warn)
        allow(instance).to receive(:puts)
      end

      context 'when we are missing ENV variables to push to influxDB' do
        before do
          stub_env(
            'QA_INFLUXDB_URL' => 'https://test.com',
            'EP_CI_JOB_METRICS_TOKEN' => nil
          )
        end

        it 'displays an error to the user' do
          allow(instance).to receive(:influx_write_api).and_call_original
          allow(instance).to receive(:warn).and_call_original

          expect { subject }.to output(
            "[job-metrics] Failed to push CI job metrics to InfluxDB, " \
              "error: Missing EP_CI_JOB_METRICS_TOKEN env variable\n"
          ).to_stderr
        end
      end

      context 'when pushing the data to InfluxDB raises an exception' do
        it 'displays an error to the user' do
          allow(instance).to receive(:warn).and_call_original
          expect(influx_write_api).to receive(:write).and_raise("connectivity issues")

          expect { subject }.to output(
            "[job-metrics] Failed to push CI job metrics to InfluxDB, error: connectivity issues\n"
          ).to_stderr
        end
      end

      context 'when some tags/fields are empty/nil' do
        before do
          allow(instance).to receive(:load_metrics_file).and_return({
            name: 'job-metrics',
            time: ENV['CI_PIPELINE_CREATED_AT'].to_time,
            tags: {
              first_tag: '',
              third_tag: 'hello'
            },
            fields: {
              second_tag: nil
            }
          })
        end

        it 'removes the metrics with empty/nil values from the metrics list' do
          expect(influx_write_api).to receive(:write).with(data: {
            name: 'job-metrics',
            time: anything,
            tags: { third_tag: 'hello' },
            fields: {
              job_duration_seconds: anything # Added right before pushing to influxDB
            }
          })

          subject
        end
      end

      it 'pushes the data to InfluxDB' do
        expect(influx_write_api).to receive(:write).with(data: metrics_hash)

        subject
      end

      it 'sets the job_duration_seconds field' do
        # We want the job to last for 10 minutes (600 seconds)
        allow(Time).to receive(:now).and_return(Time.parse(ENV.fetch('CI_JOB_STARTED_AT')) + 600)

        expect(influx_write_api).to receive(:write).with(
          data: hash_including(
            fields: hash_including(
              job_duration_seconds: 600
            )
          )
        )

        subject
      end
    end
  end

  describe '#load_metrics_file' do
    subject { instance.load_metrics_file }

    context 'when the metrics file does not exist on disk' do
      before do
        allow(File).to receive(:exist?).with(job_metrics_file_path).and_return(false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the metrics file exists on disk' do
      context 'when the metrics file does not contain valid JSON' do
        before do
          File.write(job_metrics_file_path, 'THIS IS NOT JSON CONTENT!')
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when the metrics file contains valid JSON' do
        before do
          File.write(job_metrics_file_path, { 'key' => 'value' }.to_json)
        end

        it 'returns the content of the file as a hash with symbolized keys' do
          expect(subject).to eq({ key: 'value' })
        end
      end
    end
  end

  describe '#valid_metrics_file?' do
    subject { instance.valid_metrics_file? }

    context 'when the metrics file cannot be loaded in memory' do
      before do
        allow(instance).to receive(:load_metrics_file).and_return(nil)
      end

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'when the metrics file can be loaded in memory' do
      let(:metrics_file_content) do
        { key: 'value' }
      end

      before do
        allow(instance).to receive(:load_metrics_file).and_return(metrics_file_content)
      end

      context 'when the metrics file validation succeeds' do
        before do
          allow(instance).to receive(:valid_metrics?).with(metrics_file_content).and_return(true)
        end

        it 'returns true' do
          expect(subject).to be_truthy
        end
      end

      context 'when the metrics file validation fails' do
        before do
          allow(instance).to receive(:valid_metrics?).with(metrics_file_content).and_return(false)
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end
  end

  describe '#valid_metrics?' do
    subject { instance.valid_metrics?(metrics_hash) }

    let(:metrics_hash) do
      {
        name: 'job-metrics',
        time: ENV['CI_PIPELINE_CREATED_AT'].to_time,
        tags: tags_hash,
        fields: fields_hash
      }
    end

    let(:tags_hash)   { instance.default_tags }
    let(:fields_hash) { instance.default_fields }

    describe 'metrics hash keys' do
      context 'when it is missing a key' do
        before do
          metrics_hash.delete(:time)
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end

      context 'when it has an extra key' do
        before do
          metrics_hash[:extra_key] = ''
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end

    describe 'metrics hash tags keys' do
      context 'when it is missing a key' do
        before do
          tags_hash.delete(tags_hash.each_key.first)
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end

      context 'when it has an extra key' do
        before do
          tags_hash[:extra_key] = ''
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end

    describe 'metrics hash fields keys' do
      context 'when it is missing a key' do
        before do
          fields_hash.delete(fields_hash.each_key.first)
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end

      context 'when it has an extra key' do
        before do
          fields_hash[:extra_key] = ''
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end

    context 'when the metrics hash is valid' do
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '#persist_metrics_file' do
    let(:metrics_hash) do
      { key: 'value' }.to_json
    end

    subject { instance.persist_metrics_file(metrics_hash) }

    context 'when the metrics hash is not valid' do
      before do
        allow(instance).to receive(:valid_metrics?).and_return(false)
        allow(instance).to receive(:warn)
      end

      it 'returns a warning to the user' do
        allow(instance).to receive(:warn).and_call_original

        expect { subject }.to output(
          "cannot persist the metrics, as it doesn't have the correct data structure.\n"
        ).to_stderr
      end

      it 'does not write to the metrics file' do
        expect(File).not_to receive(:write).with(job_metrics_file_path, any_args)

        subject
      end
    end

    context 'when the metrics hash is valid' do
      before do
        allow(instance).to receive(:valid_metrics?).and_return(true)
      end

      it 'persists the metrics file' do
        expect { subject }.to change { File.read(job_metrics_file_path) }.from('').to(metrics_hash.to_json)
      end
    end
  end

  describe '#default_metrics' do
    subject { instance.default_metrics }

    let(:returned_time)  { ENV['CI_PIPELINE_CREATED_AT'].to_time }
    let(:default_tags)   { instance.default_tags }
    let(:default_fields) { instance.default_fields }

    it 'returns the expected metrics keys' do
      expect(subject).to eq(
        name: 'job-metrics',
        time: returned_time,
        tags: default_tags,
        fields: default_fields
      )
    end
  end

  describe '#default_tags' do
    subject { instance.default_tags }

    it 'returns the expected tags keys' do
      expect(subject).to eq(
        job_name: ENV['CI_JOB_NAME'],
        job_stage: ENV['CI_JOB_STAGE'],
        job_status: ENV['CI_JOB_STATUS'],
        project_id: ENV['CI_PROJECT_ID'],
        rspec_retried_in_new_process: 'false',
        server_host: ENV['CI_SERVER_HOST']
      )
    end

    context 'when an ENV variable is not set' do
      before do
        stub_env('CI_JOB_NAME' => nil)
      end

      it 'replaces the value with nil' do
        expect(subject).to eq(
          job_name: nil,
          job_stage: ENV['CI_JOB_STAGE'],
          job_status: ENV['CI_JOB_STATUS'],
          project_id: ENV['CI_PROJECT_ID'],
          rspec_retried_in_new_process: 'false',
          server_host: ENV['CI_SERVER_HOST']
        )
      end
    end
  end

  describe '#default_fields' do
    subject { instance.default_fields }

    it 'returns the expected fields keys' do
      expect(subject).to eq(
        job_id: ENV['CI_JOB_ID'],
        job_duration_seconds: nil,
        merge_request_iid: ENV['CI_MERGE_REQUEST_IID'],
        pipeline_id: ENV['CI_PIPELINE_ID']
      )
    end

    context 'when an ENV variable is not set' do
      before do
        stub_env('CI_JOB_ID' => nil)
      end

      it 'replaces the value with nil' do
        expect(subject).to eq(
          job_id: nil,
          job_duration_seconds: nil,
          merge_request_iid: ENV['CI_MERGE_REQUEST_IID'],
          pipeline_id: ENV['CI_PIPELINE_ID']
        )
      end
    end
  end

  describe '#time' do
    subject { instance.time }

    let(:current_time) { '2011-01-01' }

    before do
      stub_env('CI_PIPELINE_CREATED_AT' => pipeline_created_at)
      allow(DateTime).to receive(:now).and_return(current_time)
    end

    context 'when the CI_PIPELINE_CREATED_AT env variable is set' do
      let(:pipeline_created_at) { '2000-01-01T00:00:00Z' }

      it 'returns the correct time' do
        expect(subject).to eq(pipeline_created_at)
      end
    end

    context 'when the CI_PIPELINE_CREATED_AT env variable is not set' do
      let(:pipeline_created_at) { nil }

      it 'returns the current time' do
        expect(subject).to eq(current_time)
      end
    end
  end
end
