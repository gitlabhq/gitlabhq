# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopes::ReadBoundaryRule, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:member_project) { create(:project, :private, developers: user) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:private_group) { create(:group, :private) }

  let(:rule) { described_class.new(user) }

  describe '#allowed_resource?' do
    where(:resource, :allowed) do
      ref(:member_project) | true
      ref(:public_group)   | true
      ref(:private_group)  | false
    end

    with_them do
      it { expect(rule.allowed_resource?(resource)).to be(allowed) }
    end
  end

  describe '#personal_projects_namespace' do
    it { expect(rule.personal_projects_namespace).to eq(user.namespace) }
  end
end
