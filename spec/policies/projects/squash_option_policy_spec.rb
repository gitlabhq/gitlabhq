# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SquashOptionPolicy, feature_category: :source_code_management do
  let_it_be(:protected_branch) { create(:protected_branch) }
  let_it_be(:project) { protected_branch.project }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:squash_option) do
    create(:branch_rule_squash_option, protected_branch: protected_branch, project: project)
  end

  subject(:policy) { described_class.new(user, squash_option) }

  describe 'Abilities' do
    using RSpec::Parameterized::TableSyntax

    where(:user, :ability, :allowed) do
      ref(:maintainer) | :read_squash_option    | true
      ref(:maintainer) | :create_squash_option  | true
      ref(:maintainer) | :update_squash_option  | true
      ref(:maintainer) | :delete_squash_option  | true
      ref(:developer)  | :read_squash_option    | false
      ref(:developer)  | :create_squash_option  | false
      ref(:developer)  | :update_squash_option  | false
      ref(:developer)  | :delete_squash_option  | false
      ref(:guest)      | :read_squash_option    | false
      ref(:guest)      | :create_squash_option  | false
      ref(:guest)      | :update_squash_option  | false
      ref(:guest)      | :delete_squash_option  | false
    end

    with_them do
      it { expect(policy.allowed?(ability)).to eq(allowed) }

      context 'when the squash option is a project setting' do
        let(:squash_option) { project.project_setting }

        it { expect(policy.allowed?(ability)).to eq(allowed) }
      end
    end
  end
end
