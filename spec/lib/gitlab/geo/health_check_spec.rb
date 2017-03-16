require 'spec_helper'

describe Gitlab::Geo::HealthCheck do
  let!(:secondary) { create(:geo_node, :current) }

  subject { described_class }

  describe '.perform_checks' do
    it 'returns an empty string when not running on a secondary node' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(subject.perform_checks).to be_blank
    end

    it 'returns an error when configuration file is missing for tracking DB' do
      allow(Rails.configuration).to receive(:respond_to?).with(:geo_database) { false }

      expect(subject.perform_checks).not_to be_blank
    end

    it 'returns an error when Geo database version does not match the latest migration version' do
      allow(subject).to receive(:get_database_version) { 1 }

      expect(subject.perform_checks).not_to be_blank
    end

    it 'returns an error when latest migration version does not match the Geo database version' do
      allow(subject).to receive(:get_migration_version) { 1 }

      expect(subject.perform_checks).not_to be_blank
    end
  end
end
