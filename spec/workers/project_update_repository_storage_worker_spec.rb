# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe ProjectUpdateRepositoryStorageWorker do
  let(:project) { create(:project, :repository) }

  subject { described_class.new }

  describe "#perform" do
    it "calls the update repository storage service" do
      expect_next_instance_of(Projects::UpdateRepositoryStorageService) do |instance|
        expect(instance).to receive(:execute).with('new_storage')
      end

      subject.perform(project.id, 'new_storage')
    end
  end
end
