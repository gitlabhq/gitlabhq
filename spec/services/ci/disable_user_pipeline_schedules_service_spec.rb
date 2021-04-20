# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DisableUserPipelineSchedulesService do
  describe '#execute' do
    let(:user) { create(:user) }

    subject(:service) { described_class.new.execute(user) }

    context 'when user has active pipeline schedules' do
      let(:owned_pipeline_schedule) { create(:ci_pipeline_schedule, active: true, owner: user) }

      it 'disables all active pipeline schedules', :aggregate_failures do
        expect { service }.to change { owned_pipeline_schedule.reload.active? }
      end
    end
  end
end
