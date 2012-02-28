require 'spec_helper'

describe ActivityObserver do
  let(:project)  { Factory :project } 

  describe "Merge Request created" do 
    before do 
      @merge_request = Factory :merge_request, :project => project
      @event = Event.last
    end

    it { @event.should_not be_nil }
    it { @event.project.should == project }
    it { @event.action.should == Event::Created }
    it { @event.target.should == @merge_request }
  end

  describe "Issue created" do 
    before do 
      @issue = Factory :issue, :project => project
      @event = Event.last
    end

    it { @event.should_not be_nil }
    it { @event.project.should == project }
    it { @event.action.should == Event::Created }
    it { @event.target.should == @issue }
  end

  describe "Issue commented" do 
    before do 
      @issue = Factory :issue, :project => project
      @note = Factory :note, :noteable => @issue, :project => project
      @event = Event.last
    end

    it { @event.should_not be_nil }
    it { @event.project.should == project }
    it { @event.action.should == Event::Commented }
    it { @event.target.should == @note }
  end
end
