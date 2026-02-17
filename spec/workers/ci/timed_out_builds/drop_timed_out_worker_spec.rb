# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropTimedOutWorker, feature_category: :continuous_integration do
  describe "#perform" do
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform }

    it_behaves_like 'an idempotent worker'

    it "schedules DropRunningWorker asynchronously" do
      expect(Ci::TimedOutBuilds::DropRunningWorker).to receive(:perform_async).exactly(:once)
      expect(Ci::TimedOutBuilds::DropCancelingWorker).to receive(:perform_async).exactly(:once)

      perform
    end
  end
end
