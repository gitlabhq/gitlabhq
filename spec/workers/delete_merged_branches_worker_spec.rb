# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteMergedBranchesWorker, feature_category: :source_code_management do
  subject(:worker) { described_class.new }

  let(:project) { create(:project, :repository) }

  describe "#perform" do
    it "delegates to Branches::DeleteMergedService" do
      expect_next_instance_of(::Branches::DeleteMergedService) do |instance|
        expect(instance).to receive(:execute).and_return(true)
      end

      worker.perform(project.id, project.first_owner.id)
    end

    it "returns false when project was not found" do
      expect(worker.perform('unknown', project.first_owner.id)).to be_falsy
    end
  end
end
