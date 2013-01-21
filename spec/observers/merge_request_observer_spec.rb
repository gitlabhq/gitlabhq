require 'spec_helper'

describe MergeRequestObserver do
  let(:some_user) { double(:user, id: 1) }
  let(:assignee) { double(:user, id: 2) }
  let(:author) { double(:user, id: 3) }
  let(:mr)    { double(:merge_request, id: 42, assignee: assignee, author: author) }

  before(:each) { subject.stub(:current_user).and_return(some_user) }

  subject { MergeRequestObserver.instance }

  describe '#after_create' do

    it 'is called when a merge request is created' do
      subject.should_receive(:after_create)

      MergeRequest.observers.enable :merge_request_observer do
        create(:merge_request, project: create(:project))
      end
    end

    it 'sends an email to the assignee' do
      Notify.should_receive(:new_merge_request_email).with(mr.id)
      subject.after_create(mr)
    end

    it 'does not send an email to the assignee if assignee created the merge request' do
      subject.stub(:current_user).and_return(assignee)
      Notify.should_not_receive(:new_merge_request_email)

      subject.after_create(mr)
    end
  end

  context '#after_update' do
    before(:each) do
      mr.stub(:is_being_reassigned?).and_return(false)
      mr.stub(:is_being_closed?).and_return(false)
      mr.stub(:is_being_reopened?).and_return(false)
    end

    it 'is called when a merge request is changed' do
      changed = create(:merge_request, project: create(:project))
      subject.should_receive(:after_update)

      MergeRequest.observers.enable :merge_request_observer do
        changed.title = 'I changed'
        changed.save
      end
    end

    context 'a reassigned email' do
      it 'is sent if the merge request is being reassigned' do
        mr.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:send_reassigned_email).with(mr)

        subject.after_update(mr)
      end

      it 'is not sent if the merge request is not being reassigned' do
        mr.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:send_reassigned_email)

        subject.after_update(mr)
      end
    end

    context 'a status "closed"' do
      it 'note is created if the merge request is being closed' do
        mr.should_receive(:is_being_closed?).and_return(true)
        Note.should_receive(:create_status_change_note).with(mr, some_user, 'closed')

        subject.after_update(mr)
      end

      it 'note is not created if the merge request is not being closed' do
        mr.should_receive(:is_being_closed?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(mr, some_user, 'closed')

        subject.after_update(mr)
      end

      it 'notification is delivered if the merge request being closed' do
        mr.stub(:is_being_closed?).and_return(true)
        Note.should_receive(:create_status_change_note).with(mr, some_user, 'closed')

        subject.after_update(mr)
      end

      it 'notification is not delivered if the merge request not being closed' do
        mr.stub(:is_being_closed?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(mr, some_user, 'closed')

        subject.after_update(mr)
      end

      it 'notification is delivered only to author if the merge request is being closed' do
        mr_without_assignee = double(:merge_request, id: 42, author: author, assignee: nil)
        mr_without_assignee.stub(:is_being_reassigned?).and_return(false)
        mr_without_assignee.stub(:is_being_closed?).and_return(true)
        mr_without_assignee.stub(:is_being_reopened?).and_return(false)
        Note.should_receive(:create_status_change_note).with(mr_without_assignee, some_user, 'closed')

        subject.after_update(mr_without_assignee)
      end
    end

    context 'a status "reopened"' do
      it 'note is created if the merge request is being reopened' do
        mr.should_receive(:is_being_reopened?).and_return(true)
        Note.should_receive(:create_status_change_note).with(mr, some_user, 'reopened')

        subject.after_update(mr)
      end

      it 'note is not created if the merge request is not being reopened' do
        mr.should_receive(:is_being_reopened?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(mr, some_user, 'reopened')

        subject.after_update(mr)
      end

      it 'notification is delivered if the merge request being reopened' do
        mr.stub(:is_being_reopened?).and_return(true)
        Note.should_receive(:create_status_change_note).with(mr, some_user, 'reopened')

        subject.after_update(mr)
      end

      it 'notification is not delivered if the merge request is not being reopened' do
        mr.stub(:is_being_reopened?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(mr, some_user, 'reopened')

        subject.after_update(mr)
      end

      it 'notification is delivered only to author if the merge request is being reopened' do
        mr_without_assignee = double(:merge_request, id: 42, author: author, assignee: nil)
        mr_without_assignee.stub(:is_being_reassigned?).and_return(false)
        mr_without_assignee.stub(:is_being_closed?).and_return(false)
        mr_without_assignee.stub(:is_being_reopened?).and_return(true)
        Note.should_receive(:create_status_change_note).with(mr_without_assignee, some_user, 'reopened')

        subject.after_update(mr_without_assignee)
      end
    end
  end

  describe '#send_reassigned_email' do
    let(:previous_assignee) { double(:user, id: 3) }

    before(:each) do
      mr.stub(:assignee_id).and_return(assignee.id)
      mr.stub(:assignee_id_was).and_return(previous_assignee.id)
    end

    def it_sends_a_reassigned_email_to(recipient)
      Notify.should_receive(:reassigned_merge_request_email).with(recipient, mr.id, previous_assignee.id)
    end

    def it_does_not_send_a_reassigned_email_to(recipient)
      Notify.should_not_receive(:reassigned_merge_request_email).with(recipient, mr.id, previous_assignee.id)
    end

    it 'sends a reassigned email to the previous and current assignees' do
      it_sends_a_reassigned_email_to assignee.id
      it_sends_a_reassigned_email_to previous_assignee.id

      subject.send(:send_reassigned_email, mr)
    end

    context 'does not send an email to the user who made the reassignment' do
      it 'if the user is the assignee' do
        subject.stub(:current_user).and_return(assignee)
        it_sends_a_reassigned_email_to previous_assignee.id
        it_does_not_send_a_reassigned_email_to assignee.id

        subject.send(:send_reassigned_email, mr)
      end
      it 'if the user is the previous assignee' do
        subject.stub(:current_user).and_return(previous_assignee)
        it_sends_a_reassigned_email_to assignee.id
        it_does_not_send_a_reassigned_email_to previous_assignee.id

        subject.send(:send_reassigned_email, mr)
      end
    end
  end
end
