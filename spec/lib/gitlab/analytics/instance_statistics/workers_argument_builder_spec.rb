# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::InstanceStatistics::WorkersArgumentBuilder do
  context 'when no measurement identifiers are given' do
    it 'returns empty array' do
      expect(described_class.new(measurement_identifiers: []).execute).to be_empty
    end
  end

  context 'when measurement identifiers are given' do
    let_it_be(:user_1) { create(:user) }
    let_it_be(:project_1) { create(:project, namespace: user_1.namespace, creator: user_1) }
    let_it_be(:project_2) { create(:project, namespace: user_1.namespace, creator: user_1) }
    let_it_be(:project_3) { create(:project, namespace: user_1.namespace, creator: user_1) }

    let(:recorded_at) { 2.days.ago }
    let(:projects_measurement_identifier) { ::Analytics::InstanceStatistics::Measurement.identifiers.fetch(:projects) }
    let(:users_measurement_identifier) { ::Analytics::InstanceStatistics::Measurement.identifiers.fetch(:users) }
    let(:measurement_identifiers) { [projects_measurement_identifier, users_measurement_identifier] }

    subject { described_class.new(measurement_identifiers: measurement_identifiers, recorded_at: recorded_at).execute }

    it 'returns worker arguments' do
      expect(subject).to eq([
        [projects_measurement_identifier, project_1.id, project_3.id, recorded_at],
        [users_measurement_identifier, user_1.id, user_1.id, recorded_at]
      ])
    end

    context 'when bogus measurement identifiers are given' do
      before do
        measurement_identifiers << 'bogus1'
        measurement_identifiers << 'bogus2'
      end

      it 'skips bogus measurement identifiers' do
        expect(subject).to eq([
          [projects_measurement_identifier, project_1.id, project_3.id, recorded_at],
          [users_measurement_identifier, user_1.id, user_1.id, recorded_at]
        ])
      end
    end
  end
end
