# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIntegrationsEnableSslVerification, schema: 20230616082958 do
  let(:migration) { described_class.new }
  let(:integrations) { described_class::Integration }

  before do
    integrations.create!(id: 1, type_new: 'Integrations::Bamboo') # unaffected integration
    integrations.create!(id: 2, type_new: 'Integrations::DroneCi') # no properties
    integrations.create!(
      id: 3, type_new: 'Integrations::DroneCi',
      properties: {}) # no URL
    integrations.create!(
      id: 4, type_new: 'Integrations::DroneCi',
      properties: { 'drone_url' => '' }) # blank URL
    integrations.create!(
      id: 5, type_new: 'Integrations::DroneCi',
      properties: { 'drone_url' => 'https://example.com:foo' }) # invalid URL
    integrations.create!(
      id: 6, type_new: 'Integrations::DroneCi',
      properties: { 'drone_url' => 'https://example.com' }) # unknown URL
    integrations.create!(
      id: 7, type_new: 'Integrations::DroneCi',
      properties: { 'drone_url' => 'http://cloud.drone.io' }) # no HTTPS
    integrations.create!(
      id: 8, type_new: 'Integrations::DroneCi',
      properties: { 'drone_url' => 'https://cloud.drone.io' }) # known URL
    integrations.create!(
      id: 9, type_new: 'Integrations::Teamcity',
      properties: { 'teamcity_url' => 'https://example.com' }) # unknown URL
    integrations.create!(
      id: 10, type_new: 'Integrations::Teamcity',
      properties: { 'teamcity_url' => 'https://foo.bar.teamcity.com' }) # unknown URL
    integrations.create!(
      id: 11, type_new: 'Integrations::Teamcity',
      properties: { 'teamcity_url' => 'https://teamcity.com' }) # unknown URL
    integrations.create!(
      id: 12, type_new: 'Integrations::Teamcity',
      properties: { 'teamcity_url' => 'https://customer.teamcity.com' }) # known URL
  end

  def properties(id)
    integrations.find(id).properties
  end

  it 'enables SSL verification for known-good hostnames', :aggregate_failures do
    migration.perform(1, 12)

    # Bamboo
    expect(properties(1)).to be_nil

    # DroneCi
    expect(properties(2)).to be_nil
    expect(properties(3)).not_to include('enable_ssl_verification')
    expect(properties(4)).not_to include('enable_ssl_verification')
    expect(properties(5)).not_to include('enable_ssl_verification')
    expect(properties(6)).not_to include('enable_ssl_verification')
    expect(properties(7)).not_to include('enable_ssl_verification')
    expect(properties(8)).to include('enable_ssl_verification' => true)

    # Teamcity
    expect(properties(9)).not_to include('enable_ssl_verification')
    expect(properties(10)).not_to include('enable_ssl_verification')
    expect(properties(11)).not_to include('enable_ssl_verification')
    expect(properties(12)).to include('enable_ssl_verification' => true)
  end

  it 'only updates records within the given ID range', :aggregate_failures do
    migration.perform(1, 8)

    expect(properties(8)).to include('enable_ssl_verification' => true)
    expect(properties(12)).not_to include('enable_ssl_verification')
  end

  it 'marks the job as succeeded' do
    expect(Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded)
      .with('BackfillIntegrationsEnableSslVerification', [1, 10])

    migration.perform(1, 10)
  end
end
