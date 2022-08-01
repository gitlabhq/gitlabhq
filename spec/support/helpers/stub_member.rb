# frozen_string_literal: true

module StubMember
  def self.included(base)
    Member.prepend(StubbedMember::Member)
    ProjectMember.prepend(StubbedMember::ProjectMember)
  end
end
