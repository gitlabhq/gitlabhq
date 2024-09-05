# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::PeriodicRecalculateWorker, feature_category: :permissions do
  describe '#perform' do
    it 'calls AuthorizedProjectUpdate::PeriodicRecalculateService' do
      expect_next_instance_of(AuthorizedProjectUpdate::PeriodicRecalculateService) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform
    end
  end
end
