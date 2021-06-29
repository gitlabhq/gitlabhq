# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ReferenceExtractor do
  let_it_be(:project) { create(:project) }

  before do
    project.add_developer(project.creator)
  end

  subject { described_class.new(project, project.creator) }

  it 'accesses valid user objects' do
    @u_foo = create(:user, username: 'foo')
    @u_bar = create(:user, username: 'bar')
    @u_offteam = create(:user, username: 'offteam')

    project.add_guest(@u_foo)
    project.add_guest(@u_bar)

    subject.analyze('@foo, @baduser, @bar, and @offteam')
    expect(subject.users).to match_array([@u_foo, @u_bar, @u_offteam])
  end

  it 'ignores user mentions inside specific elements' do
    @u_foo = create(:user, username: 'foo')
    @u_bar = create(:user, username: 'bar')
    @u_offteam = create(:user, username: 'offteam')

    project.add_reporter(@u_foo)
    project.add_reporter(@u_bar)

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

  describe 'directly addressed users' do
    before do
      @u_foo  = create(:user, username: 'foo')
      @u_foo2 = create(:user, username: 'foo2')
      @u_foo3 = create(:user, username: 'foo3')
      @u_foo4 = create(:user, username: 'foo4')
      @u_foo5 = create(:user, username: 'foo5')

      @u_bar  = create(:user, username: 'bar')
      @u_bar2 = create(:user, username: 'bar2')
      @u_bar3 = create(:user, username: 'bar3')
      @u_bar4 = create(:user, username: 'bar4')

      @u_tom  = create(:user, username: 'tom')
      @u_tom2 = create(:user, username: 'tom2')
    end

    context 'when a user is directly addressed' do
      it 'accesses the user object which is mentioned in the beginning of the line' do
        subject.analyze('@foo What do you think? cc: @bar, @tom')

        expect(subject.directly_addressed_users).to match_array([@u_foo])
      end

      it "doesn't access the user object if it's not mentioned in the beginning of the line" do
        subject.analyze('What do you think? cc: @bar')

        expect(subject.directly_addressed_users).to be_empty
      end
    end

    context 'when multiple users are addressed' do
      it 'accesses the user objects which are mentioned in the beginning of the line' do
        subject.analyze('@foo @bar What do you think? cc: @tom')

        expect(subject.directly_addressed_users).to match_array([@u_foo, @u_bar])
      end

      it "doesn't access the user objects if they are not mentioned in the beginning of the line" do
        subject.analyze('What do you think? cc: @foo @bar @tom')

        expect(subject.directly_addressed_users).to be_empty
      end
    end

    context 'when multiple users are addressed in different paragraphs' do
      it 'accesses user objects which are mentioned in the beginning of each paragraph' do
        subject.analyze <<-NOTE.strip_heredoc
          @foo What do you think? cc: @tom

          - @bar can you please have a look?

          >>>
          @foo2 what do you think? cc: @bar2
          >>>

          @foo3 @foo4 thank you!

          > @foo5 well done!

          1. @bar3 Can you please check? cc: @tom2
          2. @bar4 What do you this of this MR?
        NOTE

        expect(subject.directly_addressed_users).to match_array([@u_foo, @u_foo3, @u_foo4])
      end
    end
  end

  it 'does not include anchors from table of contents in issue references' do
    issue1 = create(:issue, project: project)
    issue2 = create(:issue, project: project)

    subject.analyze("not real issue <h4>#{issue1.iid}</h4>, real issue #{issue2.to_reference}")

    expect(subject.issues).to match_array([issue2])
  end

  it 'accesses valid issue objects' do
    @i0 = create(:issue, project: project)
    @i1 = create(:issue, project: project)

    subject.analyze("#{@i0.to_reference}, #{@i1.to_reference}, and #{Issue.reference_prefix}#{non_existing_record_iid}.")

    expect(subject.issues).to match_array([@i0, @i1])
  end

  it 'accesses valid merge requests' do
    @m0 = create(:merge_request, source_project: project, target_project: project, source_branch: 'markdown')
    @m1 = create(:merge_request, source_project: project, target_project: project, source_branch: 'feature_conflict')

    subject.analyze("!#{non_existing_record_iid}, !#{@m1.iid}, and !#{@m0.iid}.")

    expect(subject.merge_requests).to match_array([@m1, @m0])
  end

  it 'accesses valid labels' do
    @l0 = create(:label, title: 'one', project: project)
    @l1 = create(:label, title: 'two', project: project)
    @l2 = create(:label)

    subject.analyze("~#{@l0.id}, ~#{non_existing_record_id}, ~#{@l2.id}, ~#{@l1.id}")

    expect(subject.labels).to match_array([@l0, @l1])
  end

  it 'accesses valid snippets' do
    @s0 = create(:project_snippet, project: project)
    @s1 = create(:project_snippet, project: project)
    @s2 = create(:project_snippet)

    subject.analyze("$#{@s0.id}, $#{non_existing_record_id}, $#{@s2.id}, $#{@s1.id}")

    expect(subject.snippets).to match_array([@s0, @s1])
  end

  it 'accesses valid commits' do
    project = create(:project, :repository) { |p| p.add_developer(p.creator) }
    commit = project.commit('master')

    extractor = described_class.new(project, project.creator)
    extractor.analyze("this references commits #{commit.sha[0..6]} and 012345")
    extracted = extractor.commits

    expect(extracted.size).to eq(1)
    expect(extracted[0].sha).to eq(commit.sha)
    expect(extracted[0].message).to eq(commit.message)
  end

  it 'accesses valid commit ranges' do
    project = create(:project, :repository) { |p| p.add_developer(p.creator) }
    commit = project.commit('master')
    earlier_commit = project.commit('master~2')

    extractor = described_class.new(project, project.creator)
    extractor.analyze("this references commits #{earlier_commit.sha[0..6]}...#{commit.sha[0..6]}")
    extracted = extractor.commit_ranges

    expect(extracted.size).to eq(1)
    expect(extracted.first).to be_kind_of(CommitRange)
    expect(extracted.first.commit_from).to eq earlier_commit
    expect(extracted.first.commit_to).to eq commit
  end

  context 'with an external issue tracker' do
    let(:project) { create(:jira_project) }
    let(:issue)   { create(:issue, project: project) }

    context 'when GitLab issues are enabled' do
      it 'returns both Jira and internal issues' do
        subject.analyze("JIRA-123 and FOOBAR-4567 and #{issue.to_reference}")
        expect(subject.issues).to eq [ExternalIssue.new('JIRA-123', project),
                                      ExternalIssue.new('FOOBAR-4567', project),
                                      issue]
      end

      it 'returns only Jira issues if the internal one does not exist' do
        subject.analyze("JIRA-123 and FOOBAR-4567 and ##{non_existing_record_iid}")
        expect(subject.issues).to eq [ExternalIssue.new('JIRA-123', project),
                                      ExternalIssue.new('FOOBAR-4567', project)]
      end
    end

    context 'when GitLab issues are disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'returns only Jira issues' do
        subject.analyze("JIRA-123 and FOOBAR-4567 and #{issue.to_reference}")
        expect(subject.issues).to eq [ExternalIssue.new('JIRA-123', project),
                                      ExternalIssue.new('FOOBAR-4567', project)]
      end
    end
  end

  context 'with an inactive external issue tracker' do
    let(:project) { create(:project) }
    let!(:jira_integration) { create(:jira_integration, project: project, active: false) }
    let(:issue)   { create(:issue, project: project) }

    context 'when GitLab issues are enabled' do
      it 'returns only internal issue' do
        subject.analyze("JIRA-123 and FOOBAR-4567 and #{issue.to_reference}")
        expect(subject.issues).to eq([issue])
      end

      it 'does not return any issue if the internal one does not exist' do
        subject.analyze("JIRA-123 and FOOBAR-4567 and #999")
        expect(subject.issues).to be_empty
      end
    end
  end

  context 'with a project with an underscore' do
    let(:other_project) { create(:project, path: 'test_project') }
    let(:issue) { create(:issue, project: other_project) }

    before do
      other_project.add_developer(project.creator)
    end

    it 'handles project issue references' do
      subject.analyze("this refers issue #{issue.to_reference(project)}")

      extracted = subject.issues
      expect(extracted.size).to eq(1)
      expect(extracted).to match_array([issue])
    end
  end

  describe '#all' do
    let(:issue) { create(:issue, project: project) }
    let(:label) { create(:label, project: project) }
    let(:text) { "Ref. #{issue.to_reference} and #{label.to_reference}" }

    before do
      project.add_developer(project.creator)
      subject.analyze(text)
    end

    it 'returns all referables' do
      expect(subject.all).to match_array([issue, label])
    end
  end

  describe '.references_pattern' do
    subject { described_class.references_pattern }

    it { is_expected.to be_kind_of Regexp }
  end

  describe 'referables prefixes' do
    def prefixes
      described_class::REFERABLES.each_with_object({}) do |referable, result|
        class_name = referable.to_s.camelize
        klass = class_name.constantize if Object.const_defined?(class_name)

        next unless klass.respond_to?(:reference_prefix)

        prefix = klass.reference_prefix
        result[prefix] ||= []
        result[prefix] << referable
      end
    end

    it 'returns all supported prefixes' do
      expect(prefixes.keys.uniq).to match_array(%w(@ # ~ % ! $ & [vulnerability: *iteration:))
    end

    it 'does not allow one prefix for multiple referables if not allowed specificly' do
      # make sure you are not overriding existing prefix before changing this hash
      multiple_allowed = {
        '@' => 3
      }

      prefixes.each do |prefix, referables|
        expected_count = multiple_allowed[prefix] || 1
        expect(referables.count).to eq(expected_count)
      end
    end
  end

  describe '#references' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, project: project) }

    let(:text) { "Ref. #{issue.to_reference}" }

    subject { described_class.new(project, user) }

    before do
      subject.analyze(text)
    end

    context 'when references are visible' do
      before do
        project.add_developer(user)
      end

      it 'returns visible references of given type' do
        expect(subject.references(:issue)).to eq([issue])
      end

      it 'does not increase stateful_not_visible_counter' do
        expect { subject.references(:issue) }.not_to change { subject.stateful_not_visible_counter }
      end
    end

    it 'increases stateful_not_visible_counter' do
      expect { subject.references(:issue) }.to change { subject.stateful_not_visible_counter }.by(1)
    end
  end
end
