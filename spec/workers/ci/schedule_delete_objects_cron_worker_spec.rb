# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleDeleteObjectsCronWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'enqueues DeleteObjectsWorker jobs' do
      expect(Ci::DeleteObjectsWorker).to receive(:perform_with_capacity)

      worker.perform
    end
  end
end
