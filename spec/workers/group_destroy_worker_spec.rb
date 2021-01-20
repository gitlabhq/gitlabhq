# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDestroyWorker do
  let(:group) { create(:group) }
  let!(:project) { create(:project, namespace: group) }
  let(:user) { create(:user) }

  before do
    group.add_owner(user)
  end

  subject { described_class.new }

  describe "#perform" do
    it "deletes the project" do
      subject.perform(group.id, user.id)

      expect(Group.all).not_to include(group)
      expect(Project.all).not_to include(project)
      expect(Dir.exist?(project.path)).to be_falsey
    end
  end
end
