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
end
