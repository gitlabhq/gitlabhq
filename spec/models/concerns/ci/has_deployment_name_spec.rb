# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::HasDeploymentName do
  describe 'deployment_name?' do
    let(:build) { create(:ci_build) }

    subject { build.branch? }

    it 'does detect deployment names' do
      build.name = 'deployment'

      expect(build.deployment_name?).to be_truthy
    end

    it 'does detect partial deployment names' do
      build.name = 'do a really cool deploy'

      expect(build.deployment_name?).to be_truthy
    end

    it 'does not detect non-deployment names' do
      build.name = 'testing'

      expect(build.deployment_name?).to be_falsy
    end

    it 'is case insensitive' do
      build.name = 'DEPLOY'
      expect(build.deployment_name?).to be_truthy
    end
  end
end
