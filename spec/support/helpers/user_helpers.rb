# frozen_string_literal: true

module UserHelpers
  def create_user_from_membership(target, membership)
    generate_user_from_membership(:create, target, membership)
  end

  def build_user_from_membership(target, membership)
    generate_user_from_membership(:build, target, membership)
  end

  private

  # @param method [Symbol] FactoryBot methods :create, :build, :build_stubbed
  # @param target [Project, Group] membership target
  # @param membership [Symbol] accepts the membership levels :guest, :reporter...
  #                            and pseudo levels :non_member and :anonymous
  def generate_user_from_membership(method, target, membership)
    case membership
    when :anonymous
      nil
    when :non_member
      FactoryBot.send(method, :user, name: membership)
    when :admin
      FactoryBot.send(method, :user, :admin, name: 'admin')
    else
      # `.tap` can only be used with `create`, and if we want to `build` a user,
      # it is more performant than creating a `project_member` or `group_member`
      # with a built user
      create(:user, name: membership).tap { |u| target.add_member(u, membership) }
    end
  end
end
