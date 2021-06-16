# frozen_string_literal: true

# Specifications for behavior common to all Mentionable implementations.
# Requires a shared context containing:
# - subject { "the mentionable implementation" }
# - let(:backref_text) { "the way that +subject+ should refer to itself in backreferences " }
# - let(:set_mentionable_text) { lambda { |txt| "block that assigns txt to the subject's mentionable_text" } }

RSpec.shared_context 'mentionable context' do
  let(:project) { subject.project }
  let(:author)  { subject.author }

  let(:mentioned_issue) { create(:issue, project: project) }
  let!(:mentioned_mr) { create(:merge_request, source_project: project) }
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

RSpec.shared_examples 'a mentionable' do
  include_context 'mentionable context'

  it 'generates a descriptive back-reference' do
    expect(subject.gfm_reference).to eq(backref_text)
  end

  it "extracts references from its reference property", :clean_gitlab_redis_cache do
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

  context 'when there are cached markdown fields' do
    before do
      skip unless subject.is_a?(CacheMarkdownField)
    end

    it 'sends in cached markdown fields when appropriate' do
      subject.extractors[author] = nil
      expect_next_instance_of(Gitlab::ReferenceExtractor) do |ext|
        attrs = subject.class.mentionable_attrs.collect(&:first) & subject.cached_markdown_fields.markdown_fields
        attrs.each do |field|
          expect(ext).to receive(:analyze).with(subject.send(field), hash_including(rendered: anything))
        end
      end

      expect(subject).to receive(:cached_markdown_fields).at_least(1).and_call_original

      subject.all_references(author)
    end
  end

  it 'creates cross-reference notes', :clean_gitlab_redis_cache do
    mentioned_objects = [mentioned_issue, mentioned_mr, mentioned_commit,
                         ext_issue, ext_mr, ext_commit]

    mentioned_objects.each do |referenced|
      expect(SystemNoteService).to receive(:cross_reference)
        .with(referenced, subject.local_reference, author)
    end

    subject.create_cross_references!
  end
end

RSpec.shared_examples 'an editable mentionable' do
  include_context 'mentionable context'

  it_behaves_like 'a mentionable'

  let(:new_issues) do
    [create(:issue, project: project), create(:issue, project: ext_proj)]
  end

  context 'when there are cached markdown fields' do
    before do
      skip unless subject.is_a?(CacheMarkdownField)

      subject.save!
    end

    it 'refreshes markdown cache if necessary' do
      set_mentionable_text.call('This is a text')

      subject.extractors[author] = nil
      expect_next_instance_of(Gitlab::ReferenceExtractor) do |ext|
        subject.cached_markdown_fields.markdown_fields.each do |field|
          expect(ext).to receive(:analyze).with(subject.send(field), hash_including(rendered: anything))
        end
      end

      expect(subject).to receive(:refresh_markdown_cache).and_call_original
      expect(subject).to receive(:cached_markdown_fields).at_least(:once).and_call_original

      subject.all_references(author)
    end

    context 'when the markdown cache is stale' do
      before do
        expect(subject).to receive(:latest_cached_markdown_version).at_least(:once) do
          (Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION + 1) << 16
        end
      end

      it 'persists the refreshed cache so that it does not have to be refreshed every time' do
        expect(subject).to receive(:refresh_markdown_cache).at_least(1).and_call_original

        subject.all_references(author)

        subject.reload
        subject.all_references(author)
      end
    end
  end

  it 'creates new cross-reference notes when the mentionable text is edited' do
    subject.save!
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

RSpec.shared_examples 'mentions in description' do |mentionable_type|
  describe 'when storing user mentions' do
    before do
      mentionable.store_mentions!
    end

    context 'when mentionable description has no mentions' do
      let(:mentionable) { create(mentionable_type, description: "just some description") }

      it 'stores no mentions' do
        expect(mentionable.user_mentions.count).to eq 0
      end
    end

    context 'when mentionable description contains mentions' do
      let(:user) { create(:user) }
      let(:user2) { create(:user) }
      let(:group) { create(:group) }

      let(:mentionable_desc) { "#{user.to_reference} #{user2.to_reference} #{user.to_reference} some description #{group.to_reference(full: true)} and #{user2.to_reference} @all" }
      let(:mentionable) { create(mentionable_type, description: mentionable_desc) }

      it 'stores mentions' do
        add_member(user)

        expect(mentionable.user_mentions.count).to eq 1
        expect(mentionable.referenced_users).to match_array([user, user2])
        expect(mentionable.referenced_projects(user)).to match_array([mentionable.project].compact) # epic.project is nil, and we want empty []
        expect(mentionable.referenced_groups(user)).to match_array([group])
      end
    end
  end
end

RSpec.shared_examples 'mentions in notes' do |mentionable_type|
  context 'when mentionable notes contain mentions' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:group) { create(:group) }
    let(:note_desc) { "#{user.to_reference} #{user2.to_reference} #{user.to_reference} and #{group.to_reference(full: true)} and #{user2.to_reference} @all" }
    let!(:mentionable) { note.noteable }

    before do
      note.update!(note: note_desc)
      note.store_mentions!
      add_member(user)
    end

    it 'returns all mentionable mentions' do
      expect(mentionable.user_mentions.count).to eq 1
      expect(mentionable.referenced_users).to match_array([user, user2])
      expect(mentionable.referenced_projects(user)).to eq [mentionable.project].compact # epic.project is nil, and we want empty []
      expect(mentionable.referenced_groups(user)).to eq [group]
    end
  end
end

RSpec.shared_examples 'load mentions from DB' do |mentionable_type|
  context 'load stored mentions' do
    let_it_be(:user) { create(:user) }
    let_it_be(:mentioned_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:note_desc) { "#{mentioned_user.to_reference} and #{group.to_reference(full: true)} and @all" }

    before do
      note.update!(note: note_desc)
      note.store_mentions!
      add_member(user)
    end

    context 'when stored user mention contains ids of inexistent records' do
      before do
        user_mention = note.send(:model_user_mention)
        mention_ids = {
          mentioned_users_ids: user_mention.mentioned_users_ids.to_a << non_existing_record_id,
          mentioned_projects_ids: user_mention.mentioned_projects_ids.to_a << non_existing_record_id,
          mentioned_groups_ids: user_mention.mentioned_groups_ids.to_a << non_existing_record_id
        }
        user_mention.update!(mention_ids)
      end

      it 'filters out inexistent mentions' do
        expect(mentionable.referenced_users).to match_array([mentioned_user])
        expect(mentionable.referenced_projects(user)).to match_array([mentionable.project].compact) # epic.project is nil, and we want empty []
        expect(mentionable.referenced_groups(user)).to match_array([group])
      end
    end

    context 'when private projects and groups are mentioned' do
      let(:mega_user) { create(:user) }
      let(:private_project) { create(:project, :private) }
      let(:project_member) { create(:project_member, user: create(:user), project: private_project) }
      let(:private_group) { create(:group, :private) }
      let(:group_member) { create(:group_member, user: create(:user), group: private_group) }

      before do
        user_mention = note.send(:model_user_mention)
        mention_ids = {
          mentioned_projects_ids: user_mention.mentioned_projects_ids.to_a << private_project.id,
          mentioned_groups_ids: user_mention.mentioned_groups_ids.to_a << private_group.id
        }
        user_mention.update!(mention_ids)

        add_member(mega_user)
        private_project.add_developer(mega_user)
        private_group.add_developer(mega_user)
      end

      context 'when user has no access to some mentions' do
        it 'filters out inaccessible mentions' do
          expect(mentionable.referenced_projects(user)).to match_array([mentionable.project].compact) # epic.project is nil, and we want empty []
          expect(mentionable.referenced_groups(user)).to match_array([group])
        end
      end

      context 'when user has access to all mentions' do
        it 'returns all mentions' do
          expect(mentionable.referenced_projects(mega_user)).to match_array([mentionable.project, private_project].compact) # epic.project is nil, and we want empty []
          expect(mentionable.referenced_groups(mega_user)).to match_array([group, private_group])
        end
      end
    end
  end
end

def add_member(user)
  issuable_parent = if mentionable.is_a?(Epic)
                      mentionable.group
                    else
                      mentionable.project
                    end

  issuable_parent&.add_developer(user)
end
