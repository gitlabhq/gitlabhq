require 'spec_helper'

describe Ci::EventService do
  let(:project) { FactoryGirl.create :ci_project }
  let(:user)   { double(username: "root", id: 1) }

  before do
    Event.destroy_all
  end

  describe :remove_project do
    it "creates event" do
      Ci::EventService.new.remove_project(user, project)

      expect(Ci::Event.admin.last.description).to eq("Project \"#{project.name_with_namespace}\" has been removed by root")
    end
  end

  describe :create_project do
    it "creates event" do
      Ci::EventService.new.create_project(user, project)

      expect(Ci::Event.admin.last.description).to eq("Project \"#{project.name_with_namespace}\" has been created by root")
    end
  end

  describe :change_project_settings do
    it "creates event" do
      Ci::EventService.new.change_project_settings(user, project)

      expect(Ci::Event.last.description).to eq("User \"root\" updated projects settings")
    end
  end
end
