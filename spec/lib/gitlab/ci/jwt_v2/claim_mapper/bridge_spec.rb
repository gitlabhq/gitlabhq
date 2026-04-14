# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2::ClaimMapper::Bridge, feature_category: :continuous_integration do
  let_it_be(:sha) { '35fa264414ee3ed7d0b8a6f5da40751c8600a772' }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, ref: 'test-branch-for-claim-mapper', sha: sha) }

  let(:base_url) { "#{Settings.build_server_fqdn}/#{pipeline.project.full_path}" }

  subject(:mapper) { described_class.new(pipeline) }

  describe '#to_h' do
    it 'returns expected claims' do
      expect(mapper.to_h).to eq({
        ci_config_ref_uri: "#{base_url}//.gitlab-ci.yml@refs/heads/test-branch-for-claim-mapper",
        ci_config_sha: sha
      })
    end

    context 'when ref is a tag' do
      let_it_be(:tag) { 'test-tag-for-claim-mapper' }
      let_it_be(:pipeline) { build_stubbed(:ci_pipeline, tag: tag, ref: tag, sha: sha) }

      it 'returns expected claims' do
        expect(mapper.to_h).to eq({
          ci_config_ref_uri: "#{base_url}//.gitlab-ci.yml@refs/tags/test-tag-for-claim-mapper",
          ci_config_sha: sha
        })
      end
    end
  end
end
