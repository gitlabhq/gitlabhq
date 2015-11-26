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

  describe '.latest_update_time' do
    describe 'when events are present' do
      let(:time) { Time.utc(2015, 1, 1) }

      before do
        create(:closed_issue_event, updated_at: time)
        create(:closed_issue_event, updated_at: time + 5)
      end

      it 'returns the latest update time' do
        expect(Event.latest_update_time).to eq(time + 5)
      end
    end

    describe 'when no events exist' do
      it 'returns nil' do
        expect(Event.latest_update_time).to be_nil
      end
    end
  end

  describe '.limit_recent' do
    let!(:event1) { create(:closed_issue_event) }
    let!(:event2) { create(:closed_issue_event) }

    describe 'without an explicit limit' do
      subject { Event.limit_recent }

      it { is_expected.to eq([event2, event1]) }
    end

    describe 'with an explicit limit' do
      subject { Event.limit_recent(1) }

      it { is_expected.to eq([event2]) }
    end
  end
end
