# Specifications for behavior common to all Mentionable implementations.
# Requires a shared context containing:
# - subject { "the mentionable implementation" }
# - let(:backref_text) { "the way that +subject+ should refer to itself in backreferences " }
# - let(:set_mentionable_text) { lambda { |txt| "block that assigns txt to the subject's mentionable_text" } }

def common_mentionable_setup
  let(:project) { create :project }
  let(:author)  { subject.author }

  let(:mentioned_issue)  { create(:issue, project: project) }
  let(:mentioned_mr)     { create(:merge_request, :simple, source_project: project) }
  let(:mentioned_commit) { project.repository.commit }

  let(:ext_proj)   { create(:project, :public) }
  let(:ext_issue)  { create(:issue, project: ext_proj) }
  let(:ext_mr)     { create(:merge_request, :simple, source_project: ext_proj) }
  let(:ext_commit) { ext_proj.repository.commit }

  # Override to add known commits to the repository stub.
  let(:extra_commits) { [] }

  # A string that mentions each of the +mentioned_.*+ objects above. Mentionables should add a self-reference
  # to this string and place it in their +mentionable_text+.
  let(:ref_string) do
    cross = ext_proj.path_with_namespace

    <<-MSG.strip_heredoc
      These references are new:
        Issue:  ##{mentioned_issue.iid}
        Merge:  !#{mentioned_mr.iid}
        Commit: #{mentioned_commit.id}

      This reference is a repeat and should only be mentioned once:
        Repeat: ##{mentioned_issue.iid}

      These references are cross-referenced:
        Issue:  #{cross}##{ext_issue.iid}
        Merge:  #{cross}!#{ext_mr.iid}
        Commit: #{cross}@#{ext_commit.short_id}

      This is a self-reference and should not be mentioned at all:
        Self: #{backref_text}
    MSG
  end

  before do
    # Wire the project's repository to return the mentioned commit, and +nil+
    # for any unrecognized commits.
    commitmap = {
      mentioned_commit.id => mentioned_commit
    }
    extra_commits.each { |c| commitmap[c.short_id] = c }

    allow(project.repository).to receive(:commit) { |sha| commitmap[sha] }

    set_mentionable_text.call(ref_string)
  end
end

shared_examples 'a mentionable' do
  common_mentionable_setup

  it 'generates a descriptive back-reference' do
    expect(subject.gfm_reference).to eq(backref_text)
  end

  it "extracts references from its reference property" do
    # De-duplicate and omit itself
    refs = subject.references(project)
    expect(refs.size).to eq(6)
    expect(refs).to include(mentioned_issue)
    expect(refs).to include(mentioned_mr)
    expect(refs).to include(mentioned_commit)
    expect(refs).to include(ext_issue)
    expect(refs).to include(ext_mr)
    expect(refs).to include(ext_commit)
  end

  it 'creates cross-reference notes' do
    mentioned_objects = [mentioned_issue, mentioned_mr, mentioned_commit,
                         ext_issue, ext_mr, ext_commit]

    mentioned_objects.each do |referenced|
      expect(Note).to receive(:create_cross_reference_note).
        with(referenced, subject.local_reference, author)
    end

    subject.create_cross_references!(project, author)
  end

  it 'detects existing cross-references' do
    Note.create_cross_reference_note(mentioned_issue, subject.local_reference, author)

    expect(subject).to have_mentioned(mentioned_issue)
    expect(subject).not_to have_mentioned(mentioned_mr)
  end
end

shared_examples 'an editable mentionable' do
  common_mentionable_setup

  it_behaves_like 'a mentionable'

  let(:new_issues) do
    [create(:issue, project: project), create(:issue, project: ext_proj)]
  end

  it 'creates new cross-reference notes when the mentionable text is edited' do
    subject.save

    cross = ext_proj.path_with_namespace

    new_text = <<-MSG
      These references already existed:
        Issue:  ##{mentioned_issue.iid}
        Commit: #{mentioned_commit.id}

      This cross-project reference already existed:
        Issue:  #{cross}##{ext_issue.iid}

      These two references are introduced in an edit:
        Issue: ##{new_issues[0].iid}
        Cross: #{cross}##{new_issues[1].iid}
    MSG

    # These three objects were already referenced, and should not receive new
    # notes
    [mentioned_issue, mentioned_commit, ext_issue].each do |oldref|
      expect(Note).not_to receive(:create_cross_reference_note).
        with(oldref, any_args)
    end

    # These two issues are new and should receive reference notes
    new_issues.each do |newref|
      expect(Note).to receive(:create_cross_reference_note).
        with(newref, subject.local_reference, author)
    end

    set_mentionable_text.call(new_text)
    subject.notice_added_references(project, author)
  end
end
