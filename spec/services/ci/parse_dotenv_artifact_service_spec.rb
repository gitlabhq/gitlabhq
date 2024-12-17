# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ParseDotenvArtifactService, feature_category: :artifact_security do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, pipeline: pipeline, project: project) }
  let(:service) { described_class.new(project, nil) }

  describe '#execute' do
    subject { service.execute(artifact) }

    context 'when build has a dotenv artifact' do
      let!(:artifact) { create(:ci_job_artifact, :dotenv, job: build) }

      it 'parses the artifact' do
        expect(subject[:status]).to eq(:success)

        expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
          hash_including('key' => 'KEY1', 'value' => 'VAR1'),
          hash_including('key' => 'KEY2', 'value' => 'VAR2'))
      end

      context 'when dotenv variables are conflicting against manual variables' do
        before do
          create(:ci_job_variable, job: build, key: 'KEY1')
        end

        it 'returns an error message that there is a duplicate variable' do
          subject

          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to include("Key (key, job_id)=(KEY1, #{build.id}) already exists.")
          expect(subject[:http_status]).to eq(:bad_request)
        end
      end

      context 'when dotenv variables have duplicate variables' do
        let!(:artifact) { create(:ci_job_artifact, :dotenv, job: build) }
        let(:blob) do
          <<~EOS
            KEY1=VAR1
            KEY2=VAR2
            KEY2=VAR3
            KEY1=VAR4
          EOS
        end

        before do
          allow(artifact).to receive(:each_blob).and_yield(blob)
        end

        it 'latest values get used' do
          subject

          expect(subject[:status]).to eq(:success)

          expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
            hash_including('key' => 'KEY1', 'value' => 'VAR4'),
            hash_including('key' => 'KEY2', 'value' => 'VAR3'))
        end
      end

      context 'when parse error happens' do
        before do
          allow(service).to receive(:scan_line!) { raise described_class::ParserError, 'Invalid Format' }
        end

        it 'returns error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(described_class::ParserError, job_id: build.id)

          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq('Invalid Format')
          expect(subject[:http_status]).to eq(:bad_request)
        end
      end

      context 'when artifact size is too big' do
        before do
          allow(artifact.file).to receive(:size) { 10.kilobytes }
        end

        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq("Dotenv Artifact Too Big. Maximum Allowable Size: #{service.send(:dotenv_size_limit)}")
          expect(subject[:http_status]).to eq(:bad_request)
        end
      end

      context 'when artifact has the specified blob' do
        before do
          allow(artifact).to receive(:each_blob).and_yield(blob)
        end

        context 'when a white space trails the key' do
          let(:blob) { 'KEY1 =VAR1' }

          it 'trims the trailing space' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => 'VAR1'))
          end
        end

        context 'when multiple key/value pairs exist in one line' do
          let(:blob) { 'KEY=VARCONTAINING=EQLS' }

          it 'parses the dotenv data' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY', 'value' => 'VARCONTAINING=EQLS'))
          end
        end

        context 'when key contains UNICODE' do
          let(:blob) { '🛹=skateboard' }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq("Validation failed: Key can contain only letters, digits and '_'.")
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when value contains UNICODE' do
          let(:blob) { 'skateboard=🛹' }

          it 'parses the dotenv data' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'skateboard', 'value' => '🛹'))
          end
        end

        context 'when key contains a space' do
          let(:blob) { 'K E Y 1=VAR1' }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq("Validation failed: Key can contain only letters, digits and '_'.")
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when value contains a space' do
          let(:blob) { 'KEY1=V A R 1' }

          it 'parses the dotenv data' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => 'V A R 1'))
          end
        end

        context 'when value is double quoated' do
          let(:blob) { 'KEY1="VAR1"' }

          it 'parses the value as-is' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => '"VAR1"'))
          end
        end

        context 'when value is single quoated' do
          let(:blob) { "KEY1='VAR1'" }

          it 'parses the value as-is' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => "'VAR1'"))
          end
        end

        context 'when value has white spaces in double quote' do
          let(:blob) { 'KEY1="  VAR1  "' }

          it 'parses the value as-is' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => '"  VAR1  "'))
          end
        end

        context 'when key is missing' do
          let(:blob) { '=VAR1' }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to match(/Key can't be blank/)
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when value is missing' do
          let(:blob) { 'KEY1=' }

          it 'parses the dotenv data' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => ''))
          end
        end

        context 'when it is not dotenv format' do
          let(:blob) { "{ 'KEY1': 'VAR1' }" }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Invalid Format')
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when blob is encoded in UTF-16 LE' do
          let(:blob) { File.read(Rails.root.join('spec/fixtures/build_artifacts/dotenv_utf16_le.txt')) }

          it 'parses the dotenv data' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'MY_ENV_VAR', 'value' => 'true'),
              hash_including('key' => 'TEST2', 'value' => 'false'))
          end
        end

        context 'when more than limitated variables are specified in dotenv' do
          let(:blob) do
            StringIO.new.tap do |s|
              (service.send(:dotenv_variable_limit) + 1).times do |i|
                s << "KEY#{i}=VAR#{i}\n"
              end
            end.string
          end

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq("Dotenv files cannot have more than #{service.send(:dotenv_variable_limit)} variables")
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when variables are cross-referenced in dotenv' do
          let(:blob) do
            <<~EOS
              KEY1=VAR1
              KEY2=${KEY1}_Test
            EOS
          end

          it 'does not support variable expansion in dotenv parser' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => 'VAR1'),
              hash_including('key' => 'KEY2', 'value' => '${KEY1}_Test'))
          end
        end

        context 'when there is an empty line' do
          let(:blob) do
            <<~EOS
              KEY1=VAR1

              KEY2=VAR2
            EOS
          end

          it 'does not support empty line in dotenv parser' do
            subject

            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Invalid Format')
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when there is a comment' do
          let(:blob) do
            <<~EOS
              KEY1=VAR1         # This is variable
            EOS
          end

          it 'does not support comment in dotenv parser' do
            subject

            expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
              hash_including('key' => 'KEY1', 'value' => 'VAR1         # This is variable'))
          end
        end
      end
    end

    context 'when build does not have a dotenv artifact' do
      let!(:artifact) {}

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end
