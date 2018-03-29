# This is a helper class used by the GitLab Markdown feature spec
#
# Because the feature spec only cares about the output of the Markdown, and the
# test setup and teardown and parsing is fairly expensive, we only want to do it
# once. Unfortunately RSpec will not let you access `let`s in a `before(:all)`
# block, so we fake it by encapsulating all the shared setup in this class.
#
# The class renders `spec/fixtures/markdown.md.erb` using ERB, allowing for
# reference to the factory-created objects.
class MarkdownFeature
  include FactoryBot::Syntax::Methods

  def user
    @user ||= create(:user)
  end

  def group
    @group ||= create(:group).tap do |group|
      group.add_developer(user)
    end
  end

  # Direct references ----------------------------------------------------------

  def project
    @project ||= create(:project, :repository, group: group).tap do |project|
      project.add_master(user)
    end
  end

  def project_wiki
    @project_wiki ||= ProjectWiki.new(project, user)
  end

  def project_wiki_page
    @project_wiki_page ||= build(:wiki_page, wiki: project_wiki)
  end

  def issue
    @issue ||= create(:issue, project: project)
  end

  def merge_request
    @merge_request ||= create(:merge_request, :simple, source_project: project)
  end

  def snippet
    @snippet ||= create(:project_snippet, project: project)
  end

  def commit
    @commit ||= project.commit
  end

  def commit_range
    @commit_range ||= begin
      commit2 = project.commit('HEAD~3')
      CommitRange.new("#{commit.id}...#{commit2.id}", project)
    end
  end

  def simple_label
    @simple_label ||= create(:label, name: 'gfm', project: project)
  end

  def label
    @label ||= create(:label, name: 'awaiting feedback', project: project)
  end

  def simple_milestone
    @simple_milestone ||= create(:milestone, name: 'gfm-milestone', project: project)
  end

  def milestone
    @milestone ||= create(:milestone, name: 'next goal', project: project)
  end

  def group_milestone
    @group_milestone ||= create(:milestone, name: 'group-milestone', group: group)
  end

  def epic
    @epic ||= create(:epic, title: 'epic', group: group)
  end

  def epic_other_group
    @epic ||= create(:epic, title: 'epic')
  end

  # Cross-references -----------------------------------------------------------

  def xproject
    @xproject ||= begin
      group = create(:group, :nested)
      create(:project, :repository, namespace: group) do |project|
        project.add_developer(user)
      end
    end
  end

  def xissue
    @xissue ||= create(:issue, project: xproject)
  end

  def xmerge_request
    @xmerge_request ||= create(:merge_request, :simple, source_project: xproject)
  end

  def xsnippet
    @xsnippet ||= create(:project_snippet, project: xproject)
  end

  def xcommit
    @xcommit ||= xproject.commit
  end

  def xcommit_range
    @xcommit_range ||= begin
      xcommit2 = xproject.commit('HEAD~2')
      CommitRange.new("#{xcommit.id}...#{xcommit2.id}", xproject)
    end
  end

  def xmilestone
    @xmilestone ||= create(:milestone, project: xproject)
  end

  def urls
    Gitlab::Routing.url_helpers
  end

  def raw_markdown
    markdown = File.read(Rails.root.join('spec/fixtures/markdown.md.erb'))
    ERB.new(markdown).result(binding)
  end
end
