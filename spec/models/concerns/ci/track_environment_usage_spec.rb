# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackEnvironmentUsage do
  describe '#verifies_environment?' do
    subject { build.verifies_environment? }

    context 'when build is the verify action for the environment' do
      let(:build) do
        build_stubbed(
          :ci_build,
          ref: 'master',
          environment: 'staging',
          options: { environment: { action: 'verify' } }
        )
      end

      it { is_expected.to be_truthy }
    end

    context 'when build is not the verify action for the environment' do
      let(:build) do
        build_stubbed(
          :ci_build,
          ref: 'master',
          environment: 'staging',
          options: { environment: { action: 'start' } }
        )
      end

      it { is_expected.to be_falsey }
    end
  end

  describe 'deployment_name?' do
    let(:build) { create(:ci_build) }

    subject { build.branch? }

    it 'does detect deployment names' do
      build.name = 'deployment'

      expect(build).to be_deployment_name
    end

    it 'does detect partial deployment names' do
      build.name = 'do a really cool deploy'

      expect(build).to be_deployment_name
    end

    it 'does not detect non-deployment names' do
      build.name = 'testing'

      expect(build).not_to be_deployment_name
    end

    it 'is case insensitive' do
      build.name = 'DEPLOY'

      expect(build).to be_deployment_name
    end
  end
end
