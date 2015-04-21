require 'spec_helper'

describe Gitlab::ReferenceExtractor do
  let(:project) { create(:project) }
  subject { Gitlab::ReferenceExtractor.new(project, project.creator) }

  it 'extracts username references' do
    subject.analyze('this contains a @user reference')
    expect(subject.references[:user]).to eq([[project, 'user']])
  end

  it 'extracts issue references' do
    subject.analyze('this one talks about issue #1234')
    expect(subject.references[:issue]).to eq([[project, '1234']])
  end

  it 'extracts JIRA issue references' do
    subject.analyze('this one talks about issue JIRA-1234')
    expect(subject.references[:issue]).to eq([[project, 'JIRA-1234']])
  end

  it 'extracts merge request references' do
    subject.analyze("and here's !43, a merge request")
    expect(subject.references[:merge_request]).to eq([[project, '43']])
  end

  it 'extracts snippet ids' do
    subject.analyze('snippets like $12 get extracted as well')
    expect(subject.references[:snippet]).to eq([[project, '12']])
  end

  it 'extracts commit shas' do
    subject.analyze('commit shas 98cf0ae3 are pulled out as Strings')
    expect(subject.references[:commit]).to eq([[project, '98cf0ae3']])
  end

  it 'extracts commit ranges' do
    subject.analyze('here you go, a commit range: 98cf0ae3...98cf0ae4')
    expect(subject.references[:commit_range]).to eq([[project, '98cf0ae3...98cf0ae4']])
  end

  it 'extracts multiple references and preserves their order' do
    subject.analyze('@me and @you both care about this')
    expect(subject.references[:user]).to eq([
      [project, 'me'],
      [project, 'you']
    ])
  end

  it 'leaves the original note unmodified' do
    text = 'issue #123 is just the worst, @user'
    subject.analyze(text)
    expect(text).to eq('issue #123 is just the worst, @user')
  end

  it 'extracts no references for <pre>..</pre> blocks' do
    subject.analyze("<pre>def puts '#1 issue'\nend\n</pre>```")
    expect(subject.issues).to be_blank
  end

  it 'extracts no references for <code>..</code> blocks' do
    subject.analyze("<code>def puts '!1 request'\nend\n</code>```")
    expect(subject.merge_requests).to be_blank
  end

  it 'extracts no references for code blocks with language' do
    subject.analyze("this code:\n```ruby\ndef puts '#1 issue'\nend\n```")
    expect(subject.issues).to be_blank
  end

  it 'extracts issue references for invalid code blocks' do
    subject.analyze('test: ```this one talks about issue #1234```')
    expect(subject.references[:issue]).to eq([[project, '1234']])
  end

  it 'handles all possible kinds of references' do
    accessors = described_class::TYPES.map { |t| "#{t}s".to_sym }
    expect(subject).to respond_to(*accessors)
  end

  it 'accesses valid user objects' do
    @u_foo = create(:user, username: 'foo')
    @u_bar = create(:user, username: 'bar')
    @u_offteam = create(:user, username: 'offteam')

    project.team << [@u_foo, :reporter]
    project.team << [@u_bar, :guest]

    subject.analyze('@foo, @baduser, @bar, and @offteam')
    expect(subject.users).to eq([@u_foo, @u_bar, @u_offteam])
  end

  it 'accesses valid issue objects' do
    @i0 = create(:issue, project: project)
    @i1 = create(:issue, project: project)

    subject.analyze("##{@i0.iid}, ##{@i1.iid}, and #999.")
    expect(subject.issues).to eq([@i0, @i1])
  end

  it 'accesses valid merge requests' do
    @m0 = create(:merge_request, source_project: project, target_project: project, source_branch: 'aaa')
    @m1 = create(:merge_request, source_project: project, target_project: project, source_branch: 'bbb')

    subject.analyze("!999, !#{@m1.iid}, and !#{@m0.iid}.")
    expect(subject.merge_requests).to eq([@m1, @m0])
  end

  it 'accesses valid labels' do
    @l0 = create(:label, title: 'one', project: project)
    @l1 = create(:label, title: 'two', project: project)
    @l2 = create(:label)

    subject.analyze("~#{@l0.id}, ~999, ~#{@l2.id}, ~#{@l1.id}")
    expect(subject.labels).to eq([@l0, @l1])
  end

  it 'accesses valid snippets' do
    @s0 = create(:project_snippet, project: project)
    @s1 = create(:project_snippet, project: project)
    @s2 = create(:project_snippet)

    subject.analyze("$#{@s0.id}, $999, $#{@s2.id}, $#{@s1.id}")
    expect(subject.snippets).to eq([@s0, @s1])
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
    expect(extracted[0][0].sha).to eq(earlier_commit.sha)
    expect(extracted[0][0].message).to eq(earlier_commit.message)
    expect(extracted[0][1].sha).to eq(commit.sha)
    expect(extracted[0][1].message).to eq(commit.message)
  end

  context 'with a project with an underscore' do
    let(:other_project) { create(:project, path: 'test_project') }
    let(:issue) { create(:issue, project: other_project) }

    before do
      other_project.team << [project.creator, :developer]
    end

    it 'handles project issue references' do
      subject.analyze("this refers issue #{other_project.path_with_namespace}##{issue.iid}")
      extracted = subject.issues
      expect(extracted.size).to eq(1)
      expect(extracted).to eq([issue])
    end
  end
end
