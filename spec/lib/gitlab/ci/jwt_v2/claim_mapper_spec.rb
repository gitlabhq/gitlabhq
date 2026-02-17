# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2::ClaimMapper, feature_category: :continuous_integration do
  let_it_be(:sha) { '35fa264414ee3ed7d0b8a6f5da40751c8600a772' }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, ref: 'test-branch-for-claim-mapper', sha: sha) }

  let(:source) { :unknown_source }
  let(:url) { 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml' }
  let(:project_config) { instance_double(Gitlab::Ci::ProjectConfig, url: url, source: source) }

  let(:base_url) { "#{Settings.build_server_fqdn}/#{pipeline.project.full_path}" }
  let(:ci_config_ref_uri) { "#{base_url}//.gitlab-ci.yml@refs/heads/test-branch-for-claim-mapper" }
  let(:expected_default_return) do
    {
      ci_config_ref_uri: ci_config_ref_uri,
      ci_config_sha: sha
    }
  end

  subject(:mapper) { described_class.new(project_config, pipeline) }

  describe '#to_h' do
    context 'when default_jwt_ci_config_ref_uri is disabled' do
      before do
        stub_feature_flags(default_jwt_ci_config_ref_uri: false)
      end

      it 'returns an empty hash when source is not implemented' do
        expect(mapper.to_h).to eq({})
      end
    end

    it 'returns an default value when source is not implemented' do
      expect(mapper.to_h).to eq(expected_default_return)
    end

    context 'when passed project_config is nil' do
      let(:project_config) { nil }

      it 'returns an default value' do
        expect(mapper.to_h).to eq(expected_default_return)
      end
    end

    context 'when passed pipeline is nil' do
      let(:pipeline) { nil }

      it 'returns a nil hash' do
        expect(mapper.to_h).to eq({})
      end
    end

    context 'when mapper for source is implemented' do
      where(:source) { described_class::MAPPER_FOR_CONFIG_SOURCE.keys }
      let(:result) do
        {
          ci_config_ref_uri: 'ci_config_ref_uri',
          ci_config_sha: 'ci_config_sha'
        }
      end

      with_them do
        it 'uses mapper' do
          mapper_class = described_class::MAPPER_FOR_CONFIG_SOURCE[source]
          expect_next_instance_of(mapper_class, project_config, pipeline) do |instance|
            expect(instance).to receive(:to_h).and_return(result)
          end

          expect(mapper.to_h).to eq(result)
        end
      end
    end
  end
end
