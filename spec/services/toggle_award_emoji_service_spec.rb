require 'spec_helper'

describe ToggleAwardEmoji, services: true do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:issue)   { create(:issue, project: project) }

  before do
    project.team << [user, :master]
  end

  describe '#execute' do
    it 'removes related todos' do
      expect_any_instance_of(TodoService).to receive(:new_award_emoji).with(issue, user)

      ToggleAwardEmojiService.new(project, user).execute(issue, "thumbsdown")
    end

    it 'normalizes the emoji name' do
      expect(issue).to receive(:toggle_award_emoji).with("thumbsup", user)

      ToggleAwardEmojiService.new(project, user).execute(issue, ":+1:")
    end

    context 'when the emoji is set' do
      it 'removes the emoji' do
        create(:award_emoji, awardable: issue, user: user)

        expect { ToggleAwardEmojiService.new(project, user).execute(issue, ":+1:") }.to change { AwardEmoji.count }.by(-1)
      end
    end

    context 'when the award is not set yet' do
      it 'awards the emoji' do
        expect { ToggleAwardEmojiService.new(project, user).execute(issue, ":+1:") }.to change { AwardEmoji.count }.by(1)
      end
    end
  end
end
