# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropTimedOutWorker, feature_category: :continuous_integration do
  describe "#perform" do
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform }

    it_behaves_like 'an idempotent worker'

    it "calls DropTimedOutService" do
      expect_next_instance_of(Ci::TimedOutBuilds::DropTimedOutService) do |service|
        expect(service).to receive(:execute).exactly(:once)
      end

      perform
    end
  end
end
