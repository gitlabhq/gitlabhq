require 'spec_helper'

describe API::Discussions do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, namespace: user.namespace) }
  let(:private_user)    { create(:user) }

  before do
    project.add_reporter(user)
  end

  context "when noteable is an Issue" do
    let!(:issue) { create(:issue, project: project, author: user) }
    let!(:issue_note) { create(:discussion_note_on_issue, noteable: issue, project: project, author: user) }

    it_behaves_like "discussions API", 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:noteable) { issue }
      let(:note) { issue_note }
    end
  end

  context "when noteable is a Snippet" do
    let!(:snippet) { create(:project_snippet, project: project, author: user) }
    let!(:snippet_note) { create(:discussion_note_on_snippet, noteable: snippet, project: project, author: user) }

    it_behaves_like "discussions API", 'projects', 'snippets', 'id' do
      let(:parent) { project }
      let(:noteable) { snippet }
      let(:note) { snippet_note }
    end
  end

  context "when noteable is an Epic" do
    let(:group) { create(:group, :public) }
    let(:ext_group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }
    let!(:epic_note) { create(:discussion_note, noteable: epic, project: project, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like "discussions API", 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:noteable) { epic }
      let(:note) { epic_note }
    end
  end
end
