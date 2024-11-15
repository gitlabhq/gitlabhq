# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::SchedulePruneDeletionsWorker, feature_category: :seat_cost_management do
  subject(:worker) { described_class.new }

  describe '#perform' do
    include_examples 'an idempotent worker' do
      it 'schedules Members::PruneDeletionsWorker to be performed with capacity' do
        expect(Members::PruneDeletionsWorker).to receive(:perform_with_capacity).twice

        perform_idempotent_work
      end
    end
  end
end
