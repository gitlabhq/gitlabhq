require 'spec_helper'

describe MergeRequestObserver do
  let(:some_user) { create :user }
  let(:assignee) { create :user }
  let(:author) { create :user }
  let(:project) { create :project }
  let(:mr_mock) { double(:merge_request, id: 42, assignee: assignee, author: author).as_null_object }
  let(:assigned_mr) { create(:merge_request, assignee: assignee, author: author, source_project: project) }
  let(:unassigned_mr) { create(:merge_request, author: author, source_project: project) }
  let(:closed_assigned_mr) { create(:closed_merge_request, assignee: assignee, author: author, source_project: project) }
  let(:closed_unassigned_mr) { create(:closed_merge_request, author: author, source_project: project) }

  before { subject.stub(:current_user).and_return(some_user) }
  before { subject.stub(notification: double('NotificationService').as_null_object) }
  before { mr_mock.stub(:author_id) }
  before { mr_mock.stub(:source_project) }
  before { mr_mock.stub(:source_project) }
  before { mr_mock.stub(:project) }
  before { mr_mock.stub(:create_cross_references!).and_return(true) }
  before { Repository.any_instance.stub(commit: nil) }

  before(:each) { enable_observers }
  after(:each) { disable_observers }

  subject { MergeRequestObserver.instance }

  describe '#after_create' do
    it 'trigger notification service' do
      subject.should_receive(:notification)
      subject.after_create(mr_mock)
    end

    it 'creates cross-reference notes' do
       project = create :project
       mr_mock.stub(title: "this mr references !#{assigned_mr.id}", project: project)
       mr_mock.should_receive(:create_cross_references!).with(project, some_user)

       subject.after_create(mr_mock)
    end
  end

  context '#after_update' do
    before(:each) do
      mr_mock.stub(:is_being_reassigned?).and_return(false)
      mr_mock.stub(:notice_added_references)
    end

    it 'is called when a merge request is changed' do
      changed = create(:merge_request, source_project: project)
      subject.should_receive(:after_update)

      MergeRequest.observers.enable :merge_request_observer do
        changed.title = 'I changed'
        changed.save
      end
    end

    it 'checks for new references' do
      mr_mock.should_receive(:notice_added_references)

      subject.after_update(mr_mock)
    end

    context 'a notification' do
      it 'is sent if the merge request is being reassigned' do
        mr_mock.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:notification)

        subject.after_update(mr_mock)
      end

      it 'is not sent if the merge request is not being reassigned' do
        mr_mock.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:notification)

        subject.after_update(mr_mock)
      end
    end
  end

  context '#after_close' do
    context 'a status "closed"' do
      it 'note is created if the merge request is being closed' do
        Note.should_receive(:create_status_change_note).with(assigned_mr, assigned_mr.source_project, some_user, 'closed', nil)

        assigned_mr.close
      end

      it 'notification is delivered only to author if the merge request is being closed' do
        Note.should_receive(:create_status_change_note).with(unassigned_mr, unassigned_mr.source_project, some_user, 'closed', nil)

        unassigned_mr.close
      end
    end
  end

  context '#after_reopen' do
    context 'a status "reopened"' do
      it 'note is created if the merge request is being reopened' do
        Note.should_receive(:create_status_change_note).with(closed_assigned_mr, closed_assigned_mr.source_project, some_user, 'reopened', nil)

        closed_assigned_mr.reopen
      end

      it 'notification is delivered only to author if the merge request is being reopened' do
        Note.should_receive(:create_status_change_note).with(closed_unassigned_mr, closed_unassigned_mr.source_project, some_user, 'reopened', nil)

        closed_unassigned_mr.reopen
      end
    end
  end

  describe "Merge Request created" do
    def self.it_should_be_valid_event
      it { @event.should_not be_nil }
      it { @event.should_not be_nil }
      it { @event.project.should == project }
      it { @event.project.should == project }
    end

    before do
      @merge_request = create(:merge_request, source_project: project, source_project: project)
      @event = Event.last
    end

    it_should_be_valid_event
    it { @event.action.should == Event::CREATED }
    it { @event.target.should == @merge_request }
  end
end
