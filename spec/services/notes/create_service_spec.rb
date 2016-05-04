require 'spec_helper'

describe Notes::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe :execute do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          note: 'Awesome comment',
          noteable_type: 'Issue',
          noteable_id: issue.id
        }

        @note = Notes::CreateService.new(project, user, opts).execute
      end

      it { expect(@note).to be_valid }
      it { expect(@note.note).to eq('Awesome comment') }
    end
  end

  describe "#new_issue" do
    let(:content) do
      <<-NOTE
      My new title
      ---
      This is my body
      NOTE
    end
    let(:merge_request) { create(:merge_request) }
    let(:params) { {note: content, noteable_type: "MergeRequest", noteable_id: merge_request.id} }

    before do
      project.team << [user, :master]
    end

    it "creates a new issue" do
      expect { Notes::CreateService.new(project, user, params).new_issue }.to change { Issue.count }.by(1)
    end

    it 'sets a bota a note and a reference' do
      expect { Notes::CreateService.new(project, user, params).new_issue }.to change { Note.count }.by(2)
    end

    it "parses the note" do
      Notes::CreateService.new(project, user, params).new_issue
      new_issue = Issue.last
      
      expect(new_issue.title).to eq 'My new title'
      expect(new_issue.description).to eq 'This is my body'
    end
  end

  describe "award emoji" do
    before do
      project.team << [user, :master]
    end

    it "creates emoji note" do
      opts = {
        note: ':smile: ',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }

      @note = Notes::CreateService.new(project, user, opts).execute

      expect(@note).to be_valid
      expect(@note.note).to eq('smile')
      expect(@note.is_award).to be_truthy
    end

    it "creates regular note if emoji name is invalid" do
      opts = {
        note: ':smile: moretext: ',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }

      @note = Notes::CreateService.new(project, user, opts).execute

      expect(@note).to be_valid
      expect(@note.note).to eq(opts[:note])
      expect(@note.is_award).to be_falsy
    end
  end
end
