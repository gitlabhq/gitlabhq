# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RenameSecurityDashboardFeatureFlagToInstanceSecurityDashboard do
  let(:feature_gates) { table(:feature_gates) }

  subject(:migration) { described_class.new }

  describe '#up' do
    it 'copies the security_dashboard feature gate to a new instance_security_dashboard gate' do
      feature_gates.create!(feature_key: :security_dashboard, key: :actors, value: 'Project:1')
      feature_gates.create!(feature_key: :security_dashboard, key: :boolean, value: 'false')

      migration.up

      instance_security_dashboard_feature = feature_gates.find_by(feature_key: :instance_security_dashboard, key: :boolean)
      expect(instance_security_dashboard_feature.value).to eq('false')
    end

    context 'when there is no security_dashboard gate' do
      it 'does nothing' do
        migration.up

        instance_security_dashboard_feature = feature_gates.find_by(feature_key: :instance_security_dashboard, key: :boolean)
        expect(instance_security_dashboard_feature).to be_nil
      end
    end

    context 'when there is already an instance_security_dashboard gate' do
      it 'does nothing' do
        feature_gates.create!(feature_key: :security_dashboard, key: 'boolean', value: 'false')
        feature_gates.create!(feature_key: :instance_security_dashboard, key: 'boolean', value: 'false')

        expect { migration.up }.not_to raise_error
      end
    end
  end

  describe '#down' do
    it 'removes the instance_security_dashboard gate' do
      actors_instance_security_dashboard_feature = feature_gates.create!(feature_key: :instance_security_dashboard, key: :actors, value: 'Project:1')
      instance_security_dashboard_feature = feature_gates.create!(feature_key: :instance_security_dashboard, key: :boolean, value: 'false')

      migration.down

      expect { instance_security_dashboard_feature.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(actors_instance_security_dashboard_feature.reload).to be_present
    end
  end
end
