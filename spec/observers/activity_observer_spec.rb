require 'spec_helper'

describe ActivityObserver do
  let(:project)  { create(:project) }

  def self.it_should_be_valid_event
    it { @event.should_not be_nil }
    it { @event.project.should == project }
  end

  describe "Merge Request created" do
    before do
      MergeRequest.observers.enable :activity_observer do
        @merge_request = create(:merge_request, project: project)
        @event = Event.last
      end
    end

    it_should_be_valid_event
    it { @event.action.should == Event::Created }
    it { @event.target.should == @merge_request }
  end

  describe "Issue created" do
    before do
      Issue.observers.enable :activity_observer do
        @issue = create(:issue, project: project)
        @event = Event.last
      end
    end

    it_should_be_valid_event
    it { @event.action.should == Event::Created }
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
    it { @event.action.should == Event::Commented }
    it { @event.target.should == @note }
  end
end
