require 'spec_helper'

describe NoteObserver do
  subject { NoteObserver.instance }
  before { subject.stub(notification: double('NotificationService').as_null_object) }

  let(:team_without_author) { (1..2).map { |n| double :user, id: n } }
  let(:note) { double(:note).as_null_object }

  describe '#after_create' do

    it 'is called after a note is created' do
      subject.should_receive :after_create

      Note.observers.enable :note_observer do
        create(:note)
      end
    end

    it 'sends out notifications' do
      subject.should_receive(:notification)

      subject.after_create(note)
    end

    it 'creates cross-reference notes as appropriate' do
      @p = create(:project)
      @referenced = create(:issue, project: @p)
      @referencer = create(:issue, project: @p)
      @author = create(:user)

      Note.should_receive(:create_cross_reference_note).with(@referenced, @referencer, @author, @p)

      Note.observers.enable :note_observer do
        create(:note, project: @p, author: @author, noteable: @referencer,
          note: "Duplicate of ##{@referenced.iid}")
      end
    end

    it "doesn't cross-reference system notes" do
      Note.should_receive(:create_cross_reference_note).once

      Note.observers.enable :note_observer do
        Note.create_cross_reference_note(create(:issue), create(:issue))
      end
    end
  end

  describe '#after_update' do
    it 'checks for new cross-references' do
      note.should_receive(:notice_added_references)

      subject.after_update(note)
    end
  end
end
