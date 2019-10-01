# frozen_string_literal: true

module ProjectHelpers
  # @params target [Project] membership target
  # @params membership [Symbol] accepts the membership levels :guest, :reporter...
  #                             and phony levels :non_member and :anonymous
  def create_user_from_membership(target, membership)
    case membership
    when :anonymous
      nil
    when :non_member
      create(:user, name: membership)
    else
      create(:user, name: membership).tap { |u| target.add_user(u, membership) }
    end
  end

  def update_feature_access_level(project, access_level)
    project.update!(
      repository_access_level: access_level,
      merge_requests_access_level: access_level,
      builds_access_level: access_level
    )
  end
end
