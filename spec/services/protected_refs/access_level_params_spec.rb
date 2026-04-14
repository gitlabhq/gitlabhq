# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedRefs::AccessLevelParams, feature_category: :source_code_management do
  describe '#access_levels' do
    subject(:access_levels) { described_class.new(type, params).access_levels }

    let(:type) { :push }

    context 'when no params are provided' do
      let(:params) { {} }

      it 'returns default maintainer access level' do
        expect(access_levels).to eq([{ access_level: Gitlab::Access::MAINTAINER }])
      end
    end

    context 'when access_level param is provided' do
      let(:params) { { push_access_level: Gitlab::Access::DEVELOPER } }

      it 'returns the specified access level' do
        expect(access_levels).to eq([{ access_level: Gitlab::Access::DEVELOPER }])
      end
    end

    context 'when allowed_to_push contains only deploy_key_id entries' do
      let(:params) { { allowed_to_push: [{ deploy_key_id: 1 }, { deploy_key_id: 2 }] } }

      it 'returns only deploy key entries without default access level' do
        expect(access_levels).to contain_exactly(
          { deploy_key_id: 1 },
          { deploy_key_id: 2 }
        )
      end
    end

    context 'when allowed_to_push contains deploy_key_id entries and access_level is explicitly set' do
      let(:params) do
        {
          push_access_level: Gitlab::Access::DEVELOPER,
          allowed_to_push: [{ deploy_key_id: 1 }]
        }
      end

      it 'returns the specified access level plus deploy key entries' do
        expect(access_levels).to contain_exactly(
          { access_level: Gitlab::Access::DEVELOPER },
          { deploy_key_id: 1 }
        )
      end
    end

    context 'when allowed_to_push is empty array' do
      let(:params) { { allowed_to_push: [] } }

      it 'returns default maintainer access level' do
        expect(access_levels).to eq([{ access_level: Gitlab::Access::MAINTAINER }])
      end
    end

    context 'when allowed_to_push is nil' do
      let(:params) { { allowed_to_push: nil } }

      it 'returns default maintainer access level' do
        expect(access_levels).to eq([{ access_level: Gitlab::Access::MAINTAINER }])
      end
    end

    context 'with type :merge' do
      let(:type) { :merge }
      let(:params) { { allowed_to_merge: [{ deploy_key_id: 5 }] } }

      it 'uses the correct type for param lookup and returns only deploy key entries' do
        expect(access_levels).to eq([{ deploy_key_id: 5 }])
      end
    end

    context 'with type :create (for protected tags)' do
      let(:type) { :create }
      let(:params) { { allowed_to_create: [{ deploy_key_id: 10 }] } }

      it 'uses the correct type for param lookup and returns only deploy key entries' do
        expect(access_levels).to eq([{ deploy_key_id: 10 }])
      end
    end

    context 'when with_defaults is false' do
      subject(:access_levels) { described_class.new(type, params, with_defaults: false).access_levels }

      let(:params) { {} }

      it 'does not set default access level' do
        expect(access_levels).to eq([])
      end
    end

    context 'when with_defaults is false and deploy keys are provided' do
      subject(:access_levels) { described_class.new(type, params, with_defaults: false).access_levels }

      let(:params) { { allowed_to_push: [{ deploy_key_id: 1 }] } }

      it 'returns only deploy key entries without default access level' do
        expect(access_levels).to eq([{ deploy_key_id: 1 }])
      end
    end

    # These tests verify FOSS-specific behavior where non-deploy-key entries
    # in allowed_to_* are not processed (they are handled by EE's granular_access_levels)
    context 'when allowed_to_push contains non-deploy-key entries', unless: Gitlab.ee? do
      let(:params) { { allowed_to_push: [{ access_level: Gitlab::Access::DEVELOPER }] } }

      it 'returns default access level since deploy_key_entries is blank' do
        # In FOSS, allowed_to_push entries without deploy_key_id are ignored
        # use_default_access_level? returns true because deploy_key_entries is blank
        expect(access_levels).to eq([{ access_level: Gitlab::Access::MAINTAINER }])
      end
    end

    context 'when allowed_to_push contains mixed entries (deploy keys and non-deploy keys)', unless: Gitlab.ee? do
      let(:params) do
        {
          allowed_to_push: [
            { deploy_key_id: 1 },
            { access_level: Gitlab::Access::DEVELOPER }
          ]
        }
      end

      it 'returns only deploy key entries (non-deploy-key entries are handled by EE)' do
        # In FOSS, only deploy_key entries are extracted
        # use_default_access_level? returns false because deploy_key_entries is NOT blank
        expect(access_levels).to eq([{ deploy_key_id: 1 }])
      end
    end
  end

  # These tests directly exercise the CE use_default_access_level? method to ensure coverage.
  # In EE mode, this method is overridden, so we test the CE implementation directly.
  describe '#use_default_access_level? (CE implementation)', unless: Gitlab.ee? do
    let(:type) { :push }
    let(:instance) { described_class.new(type, {}, with_defaults: false) }

    def call_ce_use_default_access_level?(params)
      instance.send(:use_default_access_level?, params)
    end

    context 'when allowed_to_params is blank' do
      it 'returns true for nil' do
        expect(call_ce_use_default_access_level?({ allowed_to_push: nil })).to be true
      end

      it 'returns true for empty array' do
        expect(call_ce_use_default_access_level?({ allowed_to_push: [] })).to be true
      end

      it 'returns true when key is missing' do
        expect(call_ce_use_default_access_level?({})).to be true
      end
    end

    context 'when allowed_to_params has only deploy key entries' do
      it 'returns false because deploy_key_entries is NOT blank' do
        params = { allowed_to_push: [{ deploy_key_id: 1 }] }
        expect(call_ce_use_default_access_level?(params)).to be false
      end

      it 'returns false with multiple deploy key entries' do
        params = { allowed_to_push: [{ deploy_key_id: 1 }, { deploy_key_id: 2 }] }
        expect(call_ce_use_default_access_level?(params)).to be false
      end
    end

    context 'when allowed_to_params has only non-deploy-key entries' do
      it 'returns true because deploy_key_entries IS blank' do
        params = { allowed_to_push: [{ access_level: Gitlab::Access::DEVELOPER }] }
        expect(call_ce_use_default_access_level?(params)).to be true
      end

      it 'returns true with user_id entries (no deploy keys)' do
        params = { allowed_to_push: [{ user_id: 1 }] }
        expect(call_ce_use_default_access_level?(params)).to be true
      end
    end

    context 'when allowed_to_params has mixed entries' do
      it 'returns false when deploy keys are present among other entries' do
        params = { allowed_to_push: [{ deploy_key_id: 1 }, { access_level: Gitlab::Access::DEVELOPER }] }
        expect(call_ce_use_default_access_level?(params)).to be false
      end
    end

    context 'with different types' do
      let(:type) { :merge }

      it 'uses the correct type for param lookup' do
        params = { allowed_to_merge: [{ deploy_key_id: 1 }] }
        expect(call_ce_use_default_access_level?(params)).to be false
      end

      it 'returns true when the type-specific key is missing' do
        params = { allowed_to_push: [{ deploy_key_id: 1 }] }
        expect(call_ce_use_default_access_level?(params)).to be true
      end
    end
  end
end
