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
    when :admin
      create(:user, :admin, name: 'admin')
    else
      create(:user, name: membership).tap { |u| target.add_user(u, membership) }
    end
  end

  def update_feature_access_level(project, access_level)
    features = ProjectFeature::FEATURES.dup
    features.delete(:pages)
    params = features.each_with_object({}) { |feature, h| h["#{feature}_access_level"] = access_level }

    project.update!(params)
  end
end
