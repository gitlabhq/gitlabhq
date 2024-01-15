# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    RSpec.describe YamlProcessor, feature_category: :pipeline_composition do
      include StubRequests

      subject(:processor) do
        described_class.new(config, project: project, user: project.first_owner, logger: logger)
      end

      let_it_be(:project) { create(:project, :repository) }

      let(:logger) { Gitlab::Ci::Pipeline::Logger.new(project: project) }
      let(:result) { processor.execute }
      let(:builds) { result.builds }

      context 'with include:remote' do
        let(:config) do
          <<~YAML
            include:
              - remote: http://my.domain.com/config1.yml
              - remote: http://my.domain.com/config2.yml
          YAML
        end

        before do
          stub_full_request('http://my.domain.com/config1.yml')
            .to_return(body: 'build1: { script: echo Hello World }')

          stub_full_request('http://my.domain.com/config2.yml')
            .to_return(body: 'build2: { script: echo Hello World }')
        end

        it 'returns builds from included files' do
          expect(builds.pluck(:name)).to eq %w[build1 build2]
        end

        it 'stores instrumentation logs' do
          result

          expect(logger.observations_hash['config_mapper_process_duration_s']['count']).to eq(1)
        end

        # Remove with the FF ci_parallel_remote_includes
        it 'does not store log with config_file_fetch_remote_content' do
          result

          expect(logger.observations_hash).not_to have_key('config_file_fetch_remote_content_duration_s')
        end

        context 'when the FF ci_parallel_remote_includes is disabled' do
          before do
            stub_feature_flags(ci_parallel_remote_includes: false)
          end

          it 'stores log with config_file_fetch_remote_content' do
            result

            expect(logger.observations_hash['config_file_fetch_remote_content_duration_s']['count']).to eq(2)
          end

          context 'when the FF is specifically enabled for the project' do
            before do
              stub_feature_flags(ci_parallel_remote_includes: [project])
            end

            it 'does not store log with config_file_fetch_remote_content' do
              result

              expect(logger.observations_hash).not_to have_key('config_file_fetch_remote_content_duration_s')
            end
          end
        end
      end
    end
  end
end
