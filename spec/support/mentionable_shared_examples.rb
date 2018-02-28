# Specifications for behavior common to all Mentionable implementations.
# Requires a shared context containing:
# - subject { "the mentionable implementation" }
# - let(:backref_text) { "the way that +subject+ should refer to itself in backreferences " }
# - let(:set_mentionable_text) { lambda { |txt| "block that assigns txt to the subject's mentionable_text" } }

shared_context 'mentionable context' do
  let(:project) { subject.project }
  let(:author)  { subject.author }

  let(:mentioned_issue)  { create(:issue, project: project) }
  let!(:mentioned_mr)     { create(:merge_request, source_project: project) }
  let(:mentioned_commit) { project.commit("HEAD~1") }

  let(:ext_proj)   { create(:project, :public, :repository) }
  let(:ext_issue)  { create(:issue, project: ext_proj) }
  let(:ext_mr)     { create(:merge_request, :simple, source_project: ext_proj) }
  let(:ext_commit) { ext_proj.commit("HEAD~2") }

  # Override to add known commits to the repository stub.
  let(:extra_commits) { [] }

  # A string that mentions each of the +mentioned_.*+ objects above. Mentionables should add a self-reference
  # to this string and place it in their +mentionable_text+.
  let(:ref_string) do
    <<-MSG.strip_heredoc
      These references are new:
        Issue:  #{mentioned_issue.to_reference}
        Merge:  #{mentioned_mr.to_reference}
        Commit: #{mentioned_commit.to_reference}

      This reference is a repeat and should only be mentioned once:
        Repeat: #{mentioned_issue.to_reference}

      These references are cross-referenced:
        Issue:  #{ext_issue.to_reference(project)}
        Merge:  #{ext_mr.to_reference(project)}
        Commit: #{ext_commit.to_reference(project)}

      This is a self-reference and should not be mentioned at all:
        Self: #{backref_text}
    MSG
  end

  before do
    # Wire the project's repository to return the mentioned commit, and +nil+
    # for any unrecognized commits.
    allow_any_instance_of(::Repository).to receive(:commit).and_call_original
    allow_any_instance_of(::Repository).to receive(:commit).with(mentioned_commit.short_id).and_return(mentioned_commit)
    extra_commits.each do |commit|
      allow_any_instance_of(::Repository).to receive(:commit).with(commit.short_id).and_return(commit)
    end

    set_mentionable_text.call(ref_string)

    project.add_developer(author)
  end
end

shared_examples 'a mentionable' do
  include_context 'mentionable context'

  it 'generates a descriptive back-reference' do
    expect(subject.gfm_reference).to eq(backref_text)
  end

  it "extracts references from its reference property" do
    # De-duplicate and omit itself
    refs = subject.referenced_mentionables
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
      expect(SystemNoteService).to receive(:cross_reference)
        .with(referenced, subject.local_reference, author)
    end

    subject.create_cross_references!
  end
end

shared_examples 'an editable mentionable' do
  include_context 'mentionable context'

  it_behaves_like 'a mentionable'

  let(:new_issues) do
    [create(:issue, project: project), create(:issue, project: ext_proj)]
  end

  it 'creates new cross-reference notes when the mentionable text is edited' do
    subject.save
    subject.create_cross_references!

    new_text = <<-MSG.strip_heredoc
      These references already existed:

      Issue:  #{mentioned_issue.to_reference}

      Commit: #{mentioned_commit.to_reference}

      ---

      This cross-project reference already existed:

      Issue:  #{ext_issue.to_reference(project)}

      ---

      These two references are introduced in an edit:

      Issue: #{new_issues[0].to_reference}

      Cross: #{new_issues[1].to_reference(project)}
    MSG

    # These three objects were already referenced, and should not receive new
    # notes
    [mentioned_issue, mentioned_commit, ext_issue].each do |oldref|
      expect(SystemNoteService).not_to receive(:cross_reference)
        .with(oldref, any_args)
    end

    # These two issues are new and should receive reference notes
    # In the case of MergeRequests remember that cannot mention commits included in the MergeRequest
    new_issues.each do |newref|
      expect(SystemNoteService).to receive(:cross_reference)
        .with(newref, subject.local_reference, author)
    end

    set_mentionable_text.call(new_text)
    subject.create_new_cross_references!(author)
  end
end
