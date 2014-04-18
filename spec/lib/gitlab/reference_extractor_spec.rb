require 'spec_helper'

describe Gitlab::ReferenceExtractor do
  it 'extracts username references' do
    subject.analyze "this contains a @user reference"
    subject.users.should == ["user"]
  end

  it 'extracts issue references' do
    subject.analyze "this one talks about issue #1234"
    subject.issues.should == ["1234"]
  end

  it 'extracts merge request references' do
    subject.analyze "and here's !43, a merge request"
    subject.merge_requests.should == ["43"]
  end

  it 'extracts snippet ids' do
    subject.analyze "snippets like $12 get extracted as well"
    subject.snippets.should == ["12"]
  end

  it 'extracts commit shas' do
    subject.analyze "commit shas 98cf0ae3 are pulled out as Strings"
    subject.commits.should == ["98cf0ae3"]
  end

  it 'extracts multiple references and preserves their order' do
    subject.analyze "@me and @you both care about this"
    subject.users.should == ["me", "you"]
  end

  it 'leaves the original note unmodified' do
    text = "issue #123 is just the worst, @user"
    subject.analyze text
    text.should == "issue #123 is just the worst, @user"
  end

  it 'handles all possible kinds of references' do
    accessors = Gitlab::Markdown::TYPES.map { |t| "#{t}s".to_sym }
    subject.should respond_to(*accessors)
  end

  context 'with a project' do
    let(:project) { create(:project) }

    it 'accesses valid user objects on the project team' do
      @u_foo = create(:user, username: 'foo')
      @u_bar = create(:user, username: 'bar')
      create(:user, username: 'offteam')

      project.team << [@u_foo, :reporter]
      project.team << [@u_bar, :guest]

      subject.analyze "@foo, @baduser, @bar, and @offteam"
      subject.users_for(project).should == [@u_foo, @u_bar]
    end

    it 'accesses valid issue objects' do
      @i0 = create(:issue, project: project)
      @i1 = create(:issue, project: project)

      subject.analyze "##{@i0.iid}, ##{@i1.iid}, and #999."
      subject.issues_for(project).should == [@i0, @i1]
    end

    it 'accesses valid merge requests' do
      @m0 = create(:merge_request, source_project: project, target_project: project, source_branch: 'aaa')
      @m1 = create(:merge_request, source_project: project, target_project: project, source_branch: 'bbb')

      subject.analyze "!999, !#{@m1.iid}, and !#{@m0.iid}."
      subject.merge_requests_for(project).should == [@m1, @m0]
    end

    it 'accesses valid snippets' do
      @s0 = create(:project_snippet, project: project)
      @s1 = create(:project_snippet, project: project)
      @s2 = create(:project_snippet)

      subject.analyze "$#{@s0.id}, $999, $#{@s2.id}, $#{@s1.id}"
      subject.snippets_for(project).should == [@s0, @s1]
    end

    it 'accesses valid commits' do
      commit = project.repository.commit("master")

      subject.analyze "this references commits #{commit.sha[0..6]} and 012345"
      extracted = subject.commits_for(project)
      extracted.should have(1).item
      extracted[0].sha.should == commit.sha
      extracted[0].message.should == commit.message
    end
  end
end
