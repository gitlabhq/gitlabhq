# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JsonSchemaValidator, feature_category: :shared do
  describe '#validates_each' do
    let(:build_report_result) { build(:ci_build_report_result, :with_junit_success) }

    subject { validator.validate(build_report_result) }

    context 'when filename is set' do
      let(:validator) { described_class.new(attributes: [:data], filename: "build_report_result_data") }

      context 'when data is valid' do
        it 'returns no errors' do
          subject

          expect(build_report_result.errors).to be_empty
        end
      end

      context 'when data is invalid' do
        context 'when error message is not provided' do
          it 'returns default set error message i.e `must be a valid json schema`' do
            build_report_result.data = { invalid: 'data' }
            validator.validate(build_report_result)

            expect(build_report_result.errors.size).to eq(1)
            expect(build_report_result.errors.full_messages).to eq(["Data must be a valid json schema"])
          end
        end
      end

      context 'when error message is provided' do
        let(:validator) { described_class.new(attributes: [:data], filename: "build_report_result_data", message: "error in build-report-json") }

        it 'returns the provided error message' do
          build_report_result.data = { invalid: 'data' }
          validator.validate(build_report_result)

          expect(build_report_result.errors.size).to eq(1)
          expect(build_report_result.errors.full_messages).to eq(["Data error in build-report-json"])
        end
      end
    end

    context 'when filename is not set' do
      let(:validator) { described_class.new(attributes: [:data]) }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when filename is invalid' do
      let(:validator) { described_class.new(attributes: [:data], filename: "invalid$filename") }

      it 'raises a FilenameError' do
        expect { subject }.to raise_error(described_class::FilenameError)
      end
    end

    describe 'hash_conversion option' do
      context 'when hash_conversion is enabled' do
        let(:validator) { described_class.new(attributes: [:data], filename: "build_report_result_data", hash_conversion: true) }

        it 'returns no errors' do
          subject

          expect(build_report_result.errors).to be_empty
        end
      end
    end

    context 'when detail_errors is true' do
      let(:validator) { described_class.new(attributes: [:data], detail_errors: true, filename: "build_report_result_data") }

      context 'when data is valid' do
        it 'returns no errors' do
          subject

          expect(build_report_result.errors).to be_empty
        end
      end

      context 'when data is invalid' do
        it 'returns json schema is invalid' do
          build_report_result.data = { invalid: 'data' }

          subject

          expect(build_report_result.errors.size).to eq(1)
          expect(build_report_result.errors.full_messages).to match_array(
            ["Data object property at `/invalid` is a disallowed additional property"]
          )
        end
      end
    end

    context 'when validating config with oneOf JSON schema' do
      let(:config) do
        {
          run: [
            {
              name: 'hello_steps',
              step: 'gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step',
              inputs: {
                echo: 'hello steps!'
              }
            }
          ]
        }
      end

      let(:job) { Gitlab::Ci::Config::Entry::Job.new(config, name: :rspec) }
      let(:errors) { ActiveModel::Errors.new(job) }

      let(:validator) do
        described_class.new(
          attributes: [:run],
          base_directory: 'app/validators/json_schemas',
          filename: 'run_steps',
          hash_conversion: true,
          detail_errors: true
        )
      end

      before do
        job.compose!
        allow(job).to receive(:errors).and_return(errors)
      end

      subject { validator.validate(job) }

      context 'when the value is a valid array of hashes' do
        before do
          allow(job).to receive(:read_attribute_for_validation).and_return(config[:run])
        end

        it 'returns no errors' do
          subject

          expect(job.errors).to be_empty
        end
      end

      context 'when a required property is missing' do
        before do
          config[:run] = [{ name: 'hello_steps' }]
          allow(job).to receive(:read_attribute_for_validation).and_return(config[:run])
        end

        it 'returns an error message' do
          subject

          expect(job.errors).not_to be_empty
          expect("#{job.errors.first.attribute} #{job.errors.first.type}").to eq("run object at `/0` is missing required properties: step")
        end
      end

      context 'when oneOf validation fails' do
        before do
          config[:run] = [nil]
          allow(job).to receive(:read_attribute_for_validation).and_return(config[:run])
        end

        it 'returns an error message' do
          subject

          expect(job.errors).not_to be_empty
          expect("#{job.errors.first.attribute} #{job.errors.first.type}").to eq(
            "run value at `/0` is not an object"
          )
        end
      end

      context 'when there is a general validation error' do
        before do
          config[:run] = 'not an array'
          allow(job).to receive(:read_attribute_for_validation).and_return(config[:run])
        end

        it 'returns an error message' do
          subject

          expect(job.errors).not_to be_empty
          expect("#{job.errors.first.attribute} #{job.errors.first.type}").to eq("run value at root is not an array")
        end
      end

      context 'when a non-array value violates oneOf constraint' do
        let(:schema) do
          {
            "type" => "object",
            "properties" => {
              "run" => {
                "oneOf" => [
                  { required: ["step"], title: "step" },
                  { required: ["script"], title: "script" }
                ]
              }
            }
          }
        end

        let(:validator) do
          described_class.new(
            attributes: [:run],
            filename: 'test_schema',
            detail_errors: true
          )
        end

        before do
          config[:run] = 'C'
          allow(job).to receive(:read_attribute_for_validation).and_return({ run: config[:run] })
          allow(JSONSchemer).to receive(:schema).and_return(JSONSchemer.schema(schema))
          allow(File).to receive(:read).with(anything).and_return(schema.to_json)
        end

        it 'returns an error message for oneOf violation without data pointer' do
          subject

          expect(job.errors).not_to be_empty
          expect("#{job.errors.first.attribute} #{job.errors.first.type}").to eq("run should use only one of: step, script")
        end
      end
    end
  end
end
