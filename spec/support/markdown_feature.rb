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
  include FactoryGirl::Syntax::Methods

  def user
    @user ||= create(:user)
  end

  def group
    unless @group
      @group = create(:group)
      @group.add_developer(user)
    end

    @group
  end

  # Direct references ----------------------------------------------------------

  def project
    @project ||= create(:project)
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
    unless @commit_range
      commit2 = project.commit('HEAD~3')
      @commit_range = CommitRange.new("#{commit.id}...#{commit2.id}", project)
    end

    @commit_range
  end

  def simple_label
    @simple_label ||= create(:label, name: 'gfm', project: project)
  end

  def label
    @label ||= create(:label, name: 'awaiting feedback', project: project)
  end

  # Cross-references -----------------------------------------------------------

  def xproject
    unless @xproject
      namespace = create(:namespace, name: 'cross-reference')
      @xproject = create(:project, namespace: namespace)
      @xproject.team << [user, :developer]
    end

    @xproject
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
    unless @xcommit_range
      xcommit2 = xproject.commit('HEAD~2')
      @xcommit_range = CommitRange.new("#{xcommit.id}...#{xcommit2.id}", xproject)
    end

    @xcommit_range
  end

  def raw_markdown
    fixture = Rails.root.join('spec/fixtures/markdown.md.erb')
    ERB.new(File.read(fixture)).result(binding)
  end
end
