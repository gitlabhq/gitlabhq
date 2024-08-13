# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastParserService, feature_category: :static_application_security_testing do
  describe '#configuration' do
    include_context 'read ci configuration for sast enabled project'

    let(:configuration) { described_class.new(project).configuration }
    let(:secure_analyzers) { configuration['global'][0] }
    let(:sast_excluded_paths) { configuration['global'][1] }
    let(:sast_pipeline_stage) { configuration['pipeline'][0] }
    let(:sast_search_max_depth) { configuration['pipeline'][1] }
    let(:brakeman) { configuration['analyzers'][0] }
    let(:sast_brakeman_level) { brakeman['variables'][0] }
    let(:semgrep) { configuration['analyzers'][1] }
    let(:secure_analyzers_prefix) { '$CI_TEMPLATE_REGISTRY_HOST/security-products' }

    it 'parses the configuration for SAST' do
      expect(secure_analyzers['default_value']).to eql(secure_analyzers_prefix)
      expect(sast_excluded_paths['default_value']).to eql('$DEFAULT_SAST_EXCLUDED_PATHS')
      expect(sast_pipeline_stage['default_value']).to eql('test')
      expect(sast_search_max_depth['default_value']).to eql('4')
      expect(brakeman['enabled']).to be(true)
      expect(sast_brakeman_level['default_value']).to eql('1')
    end

    context 'while populating current values of the entities' do
      context 'when .gitlab-ci.yml is present' do
        it 'populates the current values from the file' do
          allow(project.repository).to receive(:blob_data_at).and_return(gitlab_ci_yml_content)
          expect(secure_analyzers['value']).to eql("registry.gitlab.com/gitlab-org/security-products/analyzers2")
          expect(sast_excluded_paths['value']).to eql('spec, executables')
          expect(sast_pipeline_stage['value']).to eql('our_custom_security_stage')
          expect(sast_search_max_depth['value']).to eql('8')
          expect(brakeman['enabled']).to be(false)
          expect(semgrep['enabled']).to be(true)
          expect(sast_brakeman_level['value']).to eql('2')
        end

        context 'SAST_EXCLUDED_ANALYZERS is set' do
          it 'enables analyzers correctly' do
            allow(project.repository).to receive(:blob_data_at).and_return(gitlab_ci_yml_excluded_analyzers_content)

            expect(brakeman['enabled']).to be(false)
            expect(semgrep['enabled']).to be(true)
          end
        end
      end

      context 'when .gitlab-ci.yml is absent' do
        it 'populates the current values with the default values' do
          allow(project.repository).to receive(:blob_data_at).and_return(nil)
          expect(secure_analyzers['value']).to eql(secure_analyzers_prefix)
          expect(sast_excluded_paths['value']).to eql('$DEFAULT_SAST_EXCLUDED_PATHS')
          expect(sast_pipeline_stage['value']).to eql('test')
          expect(sast_search_max_depth['value']).to eql('4')
          expect(brakeman['enabled']).to be(true)
          expect(sast_brakeman_level['value']).to eql('1')
        end
      end

      context 'when .gitlab-ci.yml does not include the sast job' do
        before do
          allow(project.repository).to receive(:blob_data_at).and_return(
            File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
          )
        end

        it 'populates the current values with the default values' do
          expect(secure_analyzers['value']).to eql(secure_analyzers_prefix)
          expect(sast_excluded_paths['value']).to eql('$DEFAULT_SAST_EXCLUDED_PATHS')
          expect(sast_pipeline_stage['value']).to eql('test')
          expect(sast_search_max_depth['value']).to eql('4')
          expect(brakeman['enabled']).to be(true)
          expect(sast_brakeman_level['value']).to eql('1')
        end
      end
    end
  end
end
