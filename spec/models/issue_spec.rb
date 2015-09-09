# == Schema Information
#
# Table name: issues
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  assignee_id   :integer
#  author_id     :integer
#  project_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  position      :integer          default(0)
#  branch_name   :string(255)
#  description   :text
#  milestone_id  :integer
#  state         :string(255)
#  iid           :integer
#  updated_by_id :integer
#

require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(InternalId) }
    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }
  end

  subject { create(:issue) }

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(subject.to_reference).to eq "##{subject.iid}"
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(subject.to_reference(cross)).
        to eq "#{subject.project.to_reference}##{subject.iid}"
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns true if the issue assignee has changed' do
      subject.assignee = create(:user)
      expect(subject.is_being_reassigned?).to be_truthy
    end
    it 'returns false if the issue assignee has not changed' do
      expect(subject.is_being_reassigned?).to be_falsey
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns issues assigned to user' do
      user = create(:user)
      create_list(:issue, 2, assignee: user)

      expect(Issue.open_for(user).count).to eq 2
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:issue, project: project) }

    let(:backref_text) { "issue #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt){ subject.description = txt } }
  end

  it_behaves_like 'a Taskable' do
    let(:subject) { create :issue }
  end
end
