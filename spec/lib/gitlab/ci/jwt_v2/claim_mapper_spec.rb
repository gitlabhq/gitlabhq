# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2::ClaimMapper, feature_category: :continuous_integration do
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }

  let(:source) { :unknown_source }
  let(:url) { 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml' }
  let(:project_config) { instance_double(Gitlab::Ci::ProjectConfig, url: url, source: source) }

  subject(:mapper) { described_class.new(project_config, pipeline) }

  describe '#to_h' do
    it 'returns an empty hash when source is not implemented' do
      expect(mapper.to_h).to eq({})
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
