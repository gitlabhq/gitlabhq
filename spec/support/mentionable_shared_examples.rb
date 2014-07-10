# Specifications for behavior common to all Mentionable implementations.
# Requires a shared context containing:
# - let(:subject) { "the mentionable implementation" }
# - let(:backref_text) { "the way that +subject+ should refer to itself in backreferences " }
# - let(:set_mentionable_text) { lambda { |txt| "block that assigns txt to the subject's mentionable_text" } }

def common_mentionable_setup
  # Avoid name collisions with let(:project) or let(:author) in the surrounding scope.
  let(:mproject) { create :project }
  let(:mauthor) { subject.author }

  let(:mentioned_issue) { create :issue, project: mproject }
  let(:other_issue) { create :issue, project: mproject }
  let(:mentioned_mr) { create :merge_request, :simple, source_project: mproject }
  let(:mentioned_commit) { double('commit', sha: '1234567890abcdef').as_null_object }

  # Override to add known commits to the repository stub.
  let(:extra_commits) { [] }

  # A string that mentions each of the +mentioned_.*+ objects above. Mentionables should add a self-reference
  # to this string and place it in their +mentionable_text+.
  let(:ref_string) do
    "mentions ##{mentioned_issue.iid} twice ##{mentioned_issue.iid}, !#{mentioned_mr.iid}, " +
    "#{mentioned_commit.sha[0..5]} and itself as #{backref_text}"
  end

  before do
    # Wire the project's repository to return the mentioned commit, and +nil+ for any
    # unrecognized commits.
    commitmap = { '123456' => mentioned_commit }
    extra_commits.each { |c| commitmap[c.sha[0..5]] = c }
    mproject.repository.stub(:commit) { |sha| commitmap[sha] }
    set_mentionable_text.call(ref_string)
  end
end

shared_examples 'a mentionable' do
  common_mentionable_setup

  it 'generates a descriptive back-reference' do
    subject.gfm_reference.should == backref_text
  end

  it "extracts references from its reference property" do
    # De-duplicate and omit itself
    refs = subject.references(mproject)

    refs.should have(3).items
    refs.should include(mentioned_issue)
    refs.should include(mentioned_mr)
    refs.should include(mentioned_commit)
  end

  it 'creates cross-reference notes' do
    [mentioned_issue, mentioned_mr, mentioned_commit].each do |referenced|
      Note.should_receive(:create_cross_reference_note).with(referenced, subject.local_reference, mauthor, mproject)
    end

    subject.create_cross_references!(mproject, mauthor)
  end

  it 'detects existing cross-references' do
    Note.create_cross_reference_note(mentioned_issue, subject.local_reference, mauthor, mproject)

    subject.has_mentioned?(mentioned_issue).should be_true
    subject.has_mentioned?(mentioned_mr).should be_false
  end
end

shared_examples 'an editable mentionable' do
  common_mentionable_setup

  it_behaves_like 'a mentionable'

  it 'creates new cross-reference notes when the mentionable text is edited' do
    new_text = "this text still mentions ##{mentioned_issue.iid} and #{mentioned_commit.sha[0..5]}, " +
      "but now it mentions ##{other_issue.iid}, too."

    [mentioned_issue, mentioned_commit].each do |oldref|
      Note.should_not_receive(:create_cross_reference_note).with(oldref, subject.local_reference,
        mauthor, mproject)
    end

    Note.should_receive(:create_cross_reference_note).with(other_issue, subject.local_reference, mauthor, mproject)

    subject.save
    set_mentionable_text.call(new_text)
    subject.notice_added_references(mproject, mauthor)
  end
end
