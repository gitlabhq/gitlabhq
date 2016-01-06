require 'spec_helper'

describe Gitlab::ReferenceExtractor, lib: true do
  let(:project) { create(:project) }
  subject { Gitlab::ReferenceExtractor.new(project, project.creator) }

  it 'accesses valid user objects' do
    @u_foo = create(:user, username: 'foo')
    @u_bar = create(:user, username: 'bar')
    @u_offteam = create(:user, username: 'offteam')

    project.team << [@u_foo, :reporter]
    project.team << [@u_bar, :guest]

    subject.analyze('@foo, @baduser, @bar, and @offteam')
    expect(subject.users).to match_array([@u_foo, @u_bar, @u_offteam])
  end

  it 'ignores user mentions inside specific elements' do
    @u_foo = create(:user, username: 'foo')
    @u_bar = create(:user, username: 'bar')
    @u_offteam = create(:user, username: 'offteam')

    project.team << [@u_foo, :reporter]
    project.team << [@u_bar, :guest]

    subject.analyze(%Q{
      Inline code: `@foo`

      Code block:

      ```
      @bar
      ```

      Quote:

      > @offteam
    })
    expect(subject.users).to match_array([])
  end

  it 'accesses valid issue objects' do
    @i0 = create(:issue, project: project)
    @i1 = create(:issue, project: project)

    subject.analyze("#{@i0.to_reference}, #{@i1.to_reference}, and #{Issue.reference_prefix}999.")
    expect(subject.issues).to match_array([@i0, @i1])
  end

  it 'accesses valid merge requests' do
    @m0 = create(:merge_request, source_project: project, target_project: project, source_branch: 'markdown')
    @m1 = create(:merge_request, source_project: project, target_project: project, source_branch: 'feature_conflict')

    subject.analyze("!999, !#{@m1.iid}, and !#{@m0.iid}.")
    expect(subject.merge_requests).to match_array([@m1, @m0])
  end

  it 'accesses valid labels' do
    @l0 = create(:label, title: 'one', project: project)
    @l1 = create(:label, title: 'two', project: project)
    @l2 = create(:label)

    subject.analyze("~#{@l0.id}, ~999, ~#{@l2.id}, ~#{@l1.id}")
    expect(subject.labels).to match_array([@l0, @l1])
  end

  it 'accesses valid snippets' do
    @s0 = create(:project_snippet, project: project)
    @s1 = create(:project_snippet, project: project)
    @s2 = create(:project_snippet)

    subject.analyze("$#{@s0.id}, $999, $#{@s2.id}, $#{@s1.id}")
    expect(subject.snippets).to match_array([@s0, @s1])
  end

  it 'accesses valid commits' do
    commit = project.commit('master')

    subject.analyze("this references commits #{commit.sha[0..6]} and 012345")
    extracted = subject.commits
    expect(extracted.size).to eq(1)
    expect(extracted[0].sha).to eq(commit.sha)
    expect(extracted[0].message).to eq(commit.message)
  end

  it 'accesses valid commit ranges' do
    commit = project.commit('master')
    earlier_commit = project.commit('master~2')

    subject.analyze("this references commits #{earlier_commit.sha[0..6]}...#{commit.sha[0..6]}")

    extracted = subject.commit_ranges
    expect(extracted.size).to eq(1)
    expect(extracted.first).to be_kind_of(CommitRange)
    expect(extracted.first.commit_from).to eq earlier_commit
    expect(extracted.first.commit_to).to eq commit
  end

  context 'with an external issue tracker' do
    let(:project) { create(:jira_project) }
    subject { described_class.new(project, project.creator) }

    it 'returns JIRA issues for a JIRA-integrated project' do
      subject.analyze('JIRA-123 and FOOBAR-4567')
      expect(subject.issues).to eq [JiraIssue.new('JIRA-123', project), JiraIssue.new('FOOBAR-4567', project)]
    end
  end

  context 'with a project with an underscore' do
    let(:other_project) { create(:project, path: 'test_project') }
    let(:issue) { create(:issue, project: other_project) }

    before do
      other_project.team << [project.creator, :developer]
    end

    it 'handles project issue references' do
      subject.analyze("this refers issue #{issue.to_reference(project)}")
      extracted = subject.issues
      expect(extracted.size).to eq(1)
      expect(extracted).to match_array([issue])
    end
  end
end
