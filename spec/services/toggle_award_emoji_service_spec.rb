require 'spec_helper'

describe ToggleAwardEmojiService, services: true do
  let(:project) { create(:empty_project) }
  let(:user)  { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:service) { ToggleAwardEmojiService.new(project, user) }

  describe :execute do
    before do
      project.team << [user, :master]
    end

    context "on an Issue" do

      it "toggles the awarded emoji" do
        service.execute(issue, "flag_nl")
        expect(issue.award_emoji.count).to eq 1

        service.execute(issue, "flag_nl")
        expect(issue.reload.award_emoji.count).to eq 0
      end

      it "marks the todoable as done" do
        expect_any_instance_of(TodoService).to receive(:new_award_emoji).with(issue, user)

        service.execute(issue, "flag_nl")
      end
    end

    context "on a Snippet" do
      let(:note) { create(:note, noteable: issue) }

      it "toggles the awarded emoji" do
        service.execute(note, "flag_nl")
        expect(note.award_emoji.count).to eq 1

        service.execute(note, "flag_nl")
        expect(note.reload.award_emoji.count).to eq 0
      end

      it "doesn't mark the todoable as done" do
        expect_any_instance_of(TodoService).not_to receive(:new_award_emoji).with(note, user)

        service.execute(note, "flag_nl")
      end
    end
  end
end
