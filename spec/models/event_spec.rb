# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  action      :integer
#  author_id   :integer
#

require 'spec_helper'

describe Event do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target) }
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:issue_title) }
    it { is_expected.to respond_to(:merge_request_title) }
    it { is_expected.to respond_to(:commits) }
  end

  describe "Push event" do
    before do
      project = create(:project)
      @user = project.owner

      data = {
        before: Gitlab::Git::BLANK_SHA,
        after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
        ref: "refs/heads/master",
        user_id: @user.id,
        user_name: @user.name,
        repository: {
          name: project.name,
          url: "localhost/rubinius",
          description: "",
          homepage: "localhost/rubinius",
          private: true
        }
      }

      @event = Event.create(
        project: project,
        action: Event::PUSHED,
        data: data,
        author_id: @user.id
      )
    end

    it { expect(@event.push?).to be_truthy }
    it { expect(@event.proper?).to be_truthy }
    it { expect(@event.tag?).to be_falsey }
    it { expect(@event.branch_name).to eq("master") }
    it { expect(@event.author).to eq(@user) }
  end
end
