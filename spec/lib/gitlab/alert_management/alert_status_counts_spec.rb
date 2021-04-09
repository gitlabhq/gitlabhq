# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::AlertStatusCounts do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_resolved) { create(:alert_management_alert, :resolved, project: project) }
  let_it_be(:alert_ignored) { create(:alert_management_alert, :ignored, project: project) }
  let_it_be(:alert_triggered) { create(:alert_management_alert) }

  let(:params) { {} }

  describe '#execute' do
    subject(:counts) { described_class.new(current_user, project, params) }

    context 'for an unauthorized user' do
      it 'returns zero for all statuses' do
        expect(counts.open).to eq(0)
        expect(counts.all).to eq(0)

        ::AlertManagement::Alert.status_names.each do |status|
          expect(counts.send(status)).to eq(0)
        end
      end
    end

    context 'for an authorized user' do
      before do
        project.add_developer(current_user)
      end

      it 'returns the correct counts for each status' do
        expect(counts.open).to eq(0)
        expect(counts.all).to eq(2)
        expect(counts.resolved).to eq(1)
        expect(counts.ignored).to eq(1)
        expect(counts.triggered).to eq(0)
        expect(counts.acknowledged).to eq(0)
      end

      context 'when filtering params are included' do
        let(:params) { { status: :resolved } }

        it 'returns the correct counts for each status' do
          expect(counts.open).to eq(0)
          expect(counts.all).to eq(1)
          expect(counts.resolved).to eq(1)
          expect(counts.ignored).to eq(0)
          expect(counts.triggered).to eq(0)
          expect(counts.acknowledged).to eq(0)
        end
      end

      context 'when search param is included' do
        let(:params) { { search: alert_resolved.title } }

        it 'returns the correct countss' do
          expect(counts.open).to eq(0)
          expect(counts.all).to eq(1)
          expect(counts.resolved).to eq(1)
          expect(counts.ignored).to eq(0)
          expect(counts.triggered).to eq(0)
          expect(counts.acknowledged).to eq(0)
        end
      end
    end
  end
end
