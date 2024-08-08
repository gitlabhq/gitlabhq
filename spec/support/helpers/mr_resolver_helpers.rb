# frozen_string_literal: true

module MrResolverHelpers
  def resolve_mr(project, resolver: described_class, user: current_user, **args)
    resolve(resolver, obj: project, args: args, ctx: { current_user: user }, arg_style: :internal)
  end
end
