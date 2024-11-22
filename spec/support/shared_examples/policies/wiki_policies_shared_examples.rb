# frozen_string_literal: true

RSpec.shared_examples 'model with wiki policies' do
  include UserHelpers
  include AdminModeHelper

  let(:container) { raise NotImplementedError }
  let(:user) { raise NotImplementedError }

  subject { described_class.new(user, container) }

  let_it_be(:wiki_permissions) do
    {}.tap do |permissions|
      permissions[:guest] = %i[read_wiki]
      permissions[:reporter] = permissions[:guest] + %i[download_wiki_code]
      permissions[:developer] = permissions[:reporter] + %i[create_wiki]
      permissions[:maintainer] = permissions[:developer] + %i[admin_wiki]
      permissions[:planner] = permissions[:maintainer]
      permissions[:all] = permissions[:maintainer]
    end
  end

  using RSpec::Parameterized::TableSyntax

  where(:container_level, :access_level, :membership, :access) do
    :public   | :enabled  | :admin      | :all
    :public   | :enabled  | :maintainer | :maintainer
    :public   | :enabled  | :developer  | :developer
    :public   | :enabled  | :reporter   | :reporter
    :public   | :enabled  | :planner    | :planner
    :public   | :enabled  | :guest      | :guest
    :public   | :enabled  | :non_member | :guest
    :public   | :enabled  | :anonymous  | :guest

    :public   | :private  | :admin      | :all
    :public   | :private  | :maintainer | :maintainer
    :public   | :private  | :developer  | :developer
    :public   | :private  | :reporter   | :reporter
    :public   | :private  | :planner    | :planner
    :public   | :private  | :guest      | :guest
    :public   | :private  | :non_member | nil
    :public   | :private  | :anonymous  | nil

    :public   | :disabled | :admin      | nil
    :public   | :disabled | :maintainer | nil
    :public   | :disabled | :developer  | nil
    :public   | :disabled | :reporter   | nil
    :public   | :disabled | :planner    | nil
    :public   | :disabled | :guest      | nil
    :public   | :disabled | :non_member | nil
    :public   | :disabled | :anonymous  | nil

    :internal | :enabled  | :admin      | :all
    :internal | :enabled  | :maintainer | :maintainer
    :internal | :enabled  | :developer  | :developer
    :internal | :enabled  | :reporter   | :reporter
    :internal | :enabled  | :planner    | :planner
    :internal | :enabled  | :guest      | :guest
    :internal | :enabled  | :non_member | :guest
    :internal | :enabled  | :anonymous  | nil

    :internal | :private  | :admin      | :all
    :internal | :private  | :maintainer | :maintainer
    :internal | :private  | :developer  | :developer
    :internal | :private  | :reporter   | :reporter
    :internal | :private  | :planner    | :planner
    :internal | :private  | :guest      | :guest
    :internal | :private  | :non_member | nil
    :internal | :private  | :anonymous  | nil

    :internal | :disabled | :admin      | nil
    :internal | :disabled | :maintainer | nil
    :internal | :disabled | :developer  | nil
    :internal | :disabled | :reporter   | nil
    :internal | :disabled | :planner    | nil
    :internal | :disabled | :guest      | nil
    :internal | :disabled | :non_member | nil
    :internal | :disabled | :anonymous  | nil

    :private  | :private  | :admin      | :all
    :private  | :private  | :maintainer | :maintainer
    :private  | :private  | :developer  | :developer
    :private  | :private  | :reporter   | :reporter
    :private  | :private  | :planner    | :planner
    :private  | :private  | :guest      | :guest
    :private  | :private  | :non_member | nil
    :private  | :private  | :anonymous  | nil

    :private  | :disabled | :admin      | nil
    :private  | :disabled | :maintainer | nil
    :private  | :disabled | :developer  | nil
    :private  | :disabled | :reporter   | nil
    :private  | :disabled | :planner    | nil
    :private  | :disabled | :guest      | nil
    :private  | :disabled | :non_member | nil
    :private  | :disabled | :anonymous  | nil
  end

  with_them do
    let(:user) { create_user_from_membership(container, membership) }
    let(:allowed_permissions) { wiki_permissions[access].dup || [] }
    let(:disallowed_permissions) { wiki_permissions[:all] - allowed_permissions }

    before do
      container.visibility = container_level.to_s
      set_access_level(ProjectFeature.access_level_from_str(access_level.to_s))
      enable_admin_mode!(user) if user&.admin?

      if allowed_permissions.any? && [container_level, access_level, membership] != [:private, :private, :guest]
        allowed_permissions << :download_wiki_code
      end
    end

    it 'allows actions based on membership' do
      expect_allowed(*allowed_permissions)
      expect_disallowed(*disallowed_permissions)
    end
  end
end
