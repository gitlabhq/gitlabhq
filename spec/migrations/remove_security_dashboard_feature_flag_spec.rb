# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveSecurityDashboardFeatureFlag do
  let(:feature_gates) { table(:feature_gates) }

  subject(:migration) { described_class.new }

  describe '#up' do
    it 'deletes the security_dashboard feature gate' do
      security_dashboard_feature = feature_gates.create!(feature_key: :security_dashboard, key: :boolean, value: 'false')
      actors_security_dashboard_feature = feature_gates.create!(feature_key: :security_dashboard, key: :actors, value: 'Project:1')

      migration.up

      expect { security_dashboard_feature.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(actors_security_dashboard_feature.reload).to be_present
    end
  end

  describe '#down' do
    it 'copies the instance_security_dashboard feature gate to a security_dashboard gate' do
      feature_gates.create!(feature_key: :instance_security_dashboard, key: :actors, value: 'Project:1')
      feature_gates.create!(feature_key: :instance_security_dashboard, key: 'boolean', value: 'false')

      migration.down

      security_dashboard_feature = feature_gates.find_by(feature_key: :security_dashboard, key: :boolean)
      expect(security_dashboard_feature.value).to eq('false')
    end

    context 'when there is no instance_security_dashboard gate' do
      it 'does nothing' do
        migration.down

        security_dashboard_feature = feature_gates.find_by(feature_key: :security_dashboard, key: :boolean)
        expect(security_dashboard_feature).to be_nil
      end
    end

    context 'when there already is a security_dashboard gate' do
      it 'does nothing' do
        feature_gates.create!(feature_key: :security_dashboard, key: 'boolean', value: 'false')
        feature_gates.create!(feature_key: :instance_security_dashboard, key: 'boolean', value: 'false')

        expect { migration.down }.not_to raise_error
      end
    end
  end
end
