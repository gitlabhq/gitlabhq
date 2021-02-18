# frozen_string_literal: true

require 'fileutils'

require 'spec_helper'

RSpec.describe GitGarbageCollectWorker do
  let_it_be(:project) { create(:project, :repository) }

  let(:lease_uuid) { SecureRandom.uuid }
  let(:lease_key)  { "project_housekeeping:#{project.id}" }
  let(:task)       { :full_repack }
  let(:params)     { [project.id, task, lease_key, lease_uuid] }

  subject { described_class.new }

  describe "#perform" do
    it 'calls the Projects::GitGarbageGitGarbageCollectWorker with the same params' do
      expect_next_instance_of(Projects::GitGarbageCollectWorker) do |instance|
        expect(instance).to receive(:perform).with(*params)
      end

      subject.perform(*params)
    end
  end
end
