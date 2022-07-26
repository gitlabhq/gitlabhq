# frozen_string_literal: true

module StubMember
  def self.included(base)
    GroupMember.prepend(StubbedMember::GroupMember)
    ProjectMember.prepend(StubbedMember::ProjectMember)
  end
end
