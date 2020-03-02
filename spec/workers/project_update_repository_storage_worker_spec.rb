# frozen_string_literal: true

require 'spec_helper'

describe ProjectUpdateRepositoryStorageWorker do
  let(:project) { create(:project, :repository) }

  subject { described_class.new }

  describe "#perform" do
    it "calls the update repository storage service" do
      expect_any_instance_of(Projects::UpdateRepositoryStorageService)
        .to receive(:execute).with('new_storage')

      subject.perform(project.id, 'new_storage')
    end

    it 'catches and logs RepositoryAlreadyMoved' do
      expect(Rails.logger).to receive(:info).with(/repository already moved/)

      expect { subject.perform(project.id, project.repository_storage) }.not_to raise_error
    end
  end
end
