require 'spec_helper'

describe Notes::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }
  let(:opts) do
    { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id }
  end

  describe '#execute' do
    context "valid params" do
      before do
        project.team << [user, :master]
        @note = Notes::CreateService.new(project, user, opts).execute
      end

      it { expect(@note).to be_valid }
      it { expect(@note.note).to eq(opts[:note]) }

      it_behaves_like 'note on noteable that supports slash commands' do
        let(:noteable) { create(:issue, project: project) }
      end

      it_behaves_like 'note on noteable that supports slash commands' do
        let(:noteable) { create(:merge_request, source_project: project) }
      end

      it_behaves_like 'note on noteable that does not support slash commands' do
        let(:noteable) { create(:commit, project: project) }
      end
    end
  end

  describe "award emoji" do
    before do
      project.team << [user, :master]
    end

    it "creates an award emoji" do
      opts = {
        note: ':smile: ',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }
      note = Notes::CreateService.new(project, user, opts).execute

      expect(note).to be_valid
      expect(note.name).to eq('smile')
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

    it "normalizes the emoji name" do
      opts = {
        note: ':+1:',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }

      expect_any_instance_of(TodoService).to receive(:new_award_emoji).with(issue, user)

      Notes::CreateService.new(project, user, opts).execute
    end
  end
end
