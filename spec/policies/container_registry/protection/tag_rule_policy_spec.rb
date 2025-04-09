# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::TagRulePolicy, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }

  subject { described_class.new(user, rule) }

  context 'for anonymous users' do
    let(:user) { nil }
    let_it_be(:rule) { build(:container_registry_protection_tag_rule) }

    it { expect_disallowed(:destroy_container_registry_protection_tag_rule) }
  end

  context 'for admin', :enable_admin_mode do
    let(:user) { build_stubbed(:admin) }
    let_it_be(:rule) { build(:container_registry_protection_tag_rule) }

    it { expect_allowed(:destroy_container_registry_protection_tag_rule) }
  end

  context 'for an immutable tag rule' do
    let_it_be(:rule) { build(:container_registry_protection_tag_rule, :immutable, project:) }

    where(:user_role, :expected_result) do
      :developer   | :be_disallowed
      :maintainer  | :be_disallowed
      :owner       | :be_allowed
    end

    with_them do
      before do
        project.send(:"add_#{user_role}", user)
      end

      it { is_expected.to send(expected_result, :destroy_container_registry_protection_tag_rule) }
    end
  end

  context 'for a mutable tag rule' do
    let_it_be(:rule) { build(:container_registry_protection_tag_rule, project:) }

    where(:user_role, :expected_result) do
      :developer   | :be_disallowed
      :maintainer  | :be_allowed
      :owner       | :be_allowed
    end

    with_them do
      before do
        project.send(:"add_#{user_role}", user)
      end

      it { is_expected.to send(expected_result, :destroy_container_registry_protection_tag_rule) }
    end
  end
end
