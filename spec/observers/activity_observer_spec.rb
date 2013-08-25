require 'spec_helper'

describe ActivityObserver do
  let(:project)  { create(:project) }

  before { Thread.current[:current_user] = create(:user) }

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

  describe "Ignore system notes" do
    let(:author) { create(:user) }
    let!(:issue) { create(:issue, project: project) }
    let!(:other) { create(:issue) }

    it "should not create events for status change notes" do
      expect do
        Note.observers.enable :activity_observer do
          Note.create_status_change_note(issue, project, author, 'reopened', nil)
        end
      end.to_not change { Event.count }
    end

    it "should not create events for cross-reference notes" do
      expect do
        Note.observers.enable :activity_observer do
          Note.create_cross_reference_note(issue, other, author, issue.project)
        end
      end.to_not change { Event.count }
    end
  end
end
