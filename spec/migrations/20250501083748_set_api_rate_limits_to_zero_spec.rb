# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetApiRateLimitsToZero, feature_category: :groups_and_projects do
  let(:application_settings) { table(:application_settings) }
  let(:migration) { described_class.new }

  let(:create_organization_api_limit) { 10 }

  before do
    application_settings.create!(rate_limits: { create_organization_api_limit: create_organization_api_limit })
  end

  describe '#up' do
    it 'does not modify any rate limits (no-op migration)' do
      expect { migration.up }.not_to change { application_settings.first.rate_limits }
    end
  end

  describe '#down' do
    it 'does not modify any rate limits' do
      expect { migration.down }.not_to change { application_settings.first.rate_limits }
    end
  end
end
