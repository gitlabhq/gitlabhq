# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::DeployKey do
  describe '#as_json' do
    subject { entity.as_json }

    let(:deploy_key) { create(:deploy_key, public: true) }
    let(:entity) { described_class.new(deploy_key) }

    it 'includes basic fields', :aggregate_failures do
      is_expected.to include(
        id: deploy_key.id,
        title: deploy_key.title,
        created_at: deploy_key.created_at,
        expires_at: deploy_key.expires_at,
        key: deploy_key.key,
        fingerprint_sha256: deploy_key.fingerprint_sha256
      )

      is_expected.to include(fingerprint: deploy_key.fingerprint) unless Gitlab::FIPS.enabled?
    end

    context 'when in FIPS mode', :fips_mode do
      it { is_expected.not_to have_key(:fingerprint) }
    end
  end
end
