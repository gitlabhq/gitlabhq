# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopes::GroupBoundaryRule, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:other_project) { create(:project, group: other_group) }

  let(:rule) { described_class.new(group) }

  describe '#allowed_access?' do
    where(:access, :allowed) do
      :user                 | true
      :selected_memberships | true
      :instance             | false
      :all_memberships      | false
      :personal_projects    | false
      'user'                | true
      :unknown              | false
      nil                   | false
    end

    with_them do
      it { expect(rule.allowed_access?(access)).to be(allowed) }
    end
  end

  describe '#allowed_resource?' do
    where(:resource, :allowed) do
      ref(:group)         | true
      ref(:subgroup)      | true
      ref(:project)       | true
      ref(:other_group)   | false
      ref(:other_project) | false
    end

    with_them do
      it { expect(rule.allowed_resource?(resource)).to be(allowed) }
    end
  end

  describe '#personal_projects_namespace' do
    it 'raises because a group has no personal namespace' do
      expect { rule.personal_projects_namespace }
        .to raise_error(Authz::GranularScopes::AccessNotAllowedError)
    end
  end
end
