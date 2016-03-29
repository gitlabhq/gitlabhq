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

describe Event, models: true do
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
    it { expect(@event.visible_to_user?).to be_truthy }
    it { expect(@event.tag?).to be_falsey }
    it { expect(@event.branch_name).to eq("master") }
    it { expect(@event.author).to eq(@user) }
  end

  describe '#visible_to_user?' do
    let(:project) { create(:empty_project, :public) }
    let(:non_member) { create(:user) }
    let(:member)  { create(:user) }
    let(:author) { create(:author) }
    let(:assignee) { create(:user) }
    let(:admin) { create(:admin) }
    let(:issue) { create(:issue, project: project, author: author, assignee: assignee) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignee: assignee) }
    let(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
    let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project) }
    let(:event) { Event.new(project: project, target: target, author_id: author.id) }

    before do
      project.team << [member, :developer]
    end

    context 'issue event' do
      context 'for non confidential issues' do
        let(:target) { issue }

        it { expect(event.visible_to_user?(non_member)).to eq true }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end

      context 'for confidential issues' do
        let(:target) { confidential_issue }

        it { expect(event.visible_to_user?(non_member)).to eq false }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end
    end

    context 'note event' do
      context 'on non confidential issues' do
        let(:target) { note_on_issue }

        it { expect(event.visible_to_user?(non_member)).to eq true }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end

      context 'on confidential issues' do
        let(:target) { note_on_confidential_issue }

        it { expect(event.visible_to_user?(non_member)).to eq false }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
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
