# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Reports, feature_category: :pipeline_composition do
  let(:entry) { described_class.new(config) }

  describe 'validates ALLOWED_KEYS' do
    it "expects ALLOWED_KEYS to be an artifact file_type or coverage_report" do
      expect(Ci::JobArtifact.file_types.keys.map(&:to_sym) + [:coverage_report]).to include(*described_class::ALLOWED_KEYS)
    end
  end

  describe 'validation' do
    context 'when entry config value is correct' do
      using RSpec::Parameterized::TableSyntax

      shared_examples 'a valid entry' do |keyword, file|
        describe '#value' do
          it 'returns artifacts configuration' do
            expect(entry.value).to eq({ "#{keyword}": [file] })
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      where(:keyword, :file) do
        :junit | 'junit.xml'
        :codequality | 'gl-code-quality-report.json'
        :sast | 'gl-sast-report.json'
        :secret_detection | 'gl-secret-detection-report.json'
        :dependency_scanning | 'gl-dependency-scanning-report.json'
        :container_scanning | 'gl-container-scanning-report.json'
        :cluster_image_scanning | 'gl-cluster-image-scanning-report.json'
        :dast | 'gl-dast-report.json'
        :license_scanning | 'gl-license-scanning-report.json'
        :performance | 'performance.json'
        :browser_performance | 'browser-performance.json'
        :browser_performance | 'performance.json'
        :load_performance | 'load-performance.json'
        :lsif | 'lsif.json'
        :dotenv | 'build.dotenv'
        :terraform | 'tfplan.json'
        :accessibility | 'gl-accessibility.json'
        :cyclonedx | 'gl-sbom.cdx.zip'
        :annotations | 'gl-annotations.json'
        :repository_xray | 'gl-repository-xray.json'
      end

      with_them do
        context 'when value is an array' do
          let(:config) { { "#{keyword}": [file] } }

          it_behaves_like 'a valid entry', params[:keyword], params[:file]
        end

        context 'when value is not array' do
          let(:config) { { "#{keyword}": file } }

          it_behaves_like 'a valid entry', params[:keyword], params[:file]
        end
      end

      context 'when coverage_report is specified' do
        let(:coverage_format) { :cobertura }
        let(:filename) { 'cobertura-coverage.xml' }
        let(:coverage_report) { { path: filename, coverage_format: coverage_format } }
        let(:config) { { coverage_report: coverage_report } }

        it 'is valid' do
          expect(entry).to be_valid
        end

        it 'returns artifacts configuration' do
          expect(entry.value).to eq(config)
        end

        context 'and another report is specified' do
          let(:config) { { coverage_report: coverage_report, dast: 'gl-dast-report.json' } }

          it 'is valid' do
            expect(entry).to be_valid
          end

          it 'returns artifacts configuration' do
            expect(entry.value).to eq({ coverage_report: coverage_report, dast: ['gl-dast-report.json'] })
          end
        end
      end

      context 'when coverage_report is nil' do
        let(:config) { { coverage_report: nil } }

        it 'is valid' do
          expect(entry).to be_valid
        end

        it 'returns artifacts configuration as an empty hash' do
          expect(entry.value).to eq({})
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when value of attribute is invalid' do
          where(key: described_class::ALLOWED_KEYS) do
            let(:config) { { "#{key}": 10 } }

            it 'reports error' do
              expect(entry.errors)
                .to include "reports #{key} should be an array of strings or a string"
            end
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { codeclimate: 'codeclimate.json' } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'reports config contains unknown keys: codeclimate'
          end
        end
      end
    end
  end
end
