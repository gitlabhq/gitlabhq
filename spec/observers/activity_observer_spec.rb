require 'spec_helper'

describe ActivityObserver do
  let(:project)  { create(:project) }

  def self.it_should_be_valid_event
    it { @event.should_not be_nil }
    it { @event.project.should == project }
  end

  describe "Issue created" do
    before do
      Issue.observers.enable :activity_observer do
        @issue = create(:issue, project: project)
        @event = Event.last
      end
    end

    it_should_be_valid_event
    it { @event.action.should == Event::CREATED }
    it { @event.target.should == @issue }
  end

  describe "Issue commented" do
    before do
      Note.observers.enable :activity_observer do
        @issue = create(:issue, project: project)
        @note = create(:note, noteable: @issue, project: project, author: @issue.author)
        @event = Event.last
      end
    end

    it_should_be_valid_event
    it { @event.action.should == Event::COMMENTED }
    it { @event.target.should == @note }
  end
end
