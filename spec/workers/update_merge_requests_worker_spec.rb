# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateMergeRequestsWorker do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  subject { described_class.new }

  describe '#perform' do
    let(:oldrev) { "123456" }
    let(:newrev) { "789012" }
    let(:ref)    { "refs/heads/test" }

    def perform
      subject.perform(project.id, user.id, oldrev, newrev, ref)
    end

    it 'executes MergeRequests::RefreshService with expected values' do
      expect_next_instance_of(MergeRequests::RefreshService, project: project, current_user: user) do |refresh_service|
        expect(refresh_service).to receive(:execute).with(oldrev, newrev, ref)
      end

      perform
    end
  end
end
