require 'spec_helper'

describe Notes::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe :execute do
    context "valid params" do
      let(:opts) { { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id } }
      let(:note) { Notes::CreateService.new(project, user, opts).execute }

      before do
        project.team << [user, :master]
      end

      it { expect(note).to be_valid }
      it { expect(note.note).to eq('Awesome comment') }
    end
  end

  describe "award emoji" do
    before do
      project.team << [user, :master]
    end

    it "skips awards emoji" do
      opts = {
        note: ':smile: ',
        noteable_type: 'Issue',
        noteable_id: issue.id,
      }

      expect { Notes::CreateService.new(project, user, opts).execute }.not_to change { Note.count }
    end

    it "creates regular note if emoji name is invalid" do
      opts = {
        note: ':smile: moretext: ',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }

      note = Notes::CreateService.new(project, user, opts).execute

      expect(note).to be_valid
      expect(note.note).to eq(opts[:note])
    end
  end
end
