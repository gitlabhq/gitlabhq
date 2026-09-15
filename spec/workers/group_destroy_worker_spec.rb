# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDestroyWorker, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker' do
    let(:job_args) { [group.id, user.id] }

    it 'does not change groups when run twice' do
      expect { worker.perform(group.id, user.id) }.to change { Group.count }.by(-1)
      expect { worker.perform(group.id, user.id) }.not_to change { Group.count }
    end
  end

  describe "#perform" do
    it "deletes the group and associated projects" do
      worker.perform(group.id, user.id)

      expect(Group.all).not_to include(group)
      expect(Project.all).not_to include(project)
      expect(Dir.exist?(project.path)).to be_falsey
    end
  end

  describe 'concurrency limit' do
    it 'overrides the default with a positive application setting' do
      stub_application_setting(group_deletion_jobs_concurrency_limit: 25)

      expect(described_class.get_concurrency_limit).to eq(25)
    end

    it 'falls back to the default calculation when the setting is 0' do
      stub_application_setting(group_deletion_jobs_concurrency_limit: 0)

      expect(described_class).to receive(:calculate_default_limit_from_max_percentage).and_return(42)
      expect(described_class.get_concurrency_limit).to eq(42)
    end
  end
end
