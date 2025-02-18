# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::TagPolicy, feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }
  let_it_be(:repository) { create(:container_repository, project: project) }

  let(:tag) { ContainerRegistry::Tag.new(repository, 'tag') }

  subject { described_class.new(user, tag) }

  describe 'destroy_container_image' do
    using RSpec::Parameterized::TableSyntax

    shared_examples 'matching expected result with protection rules' do
      let(:protection_rule) do
        build(:container_registry_protection_tag_rule, minimum_access_level_for_delete: minimum_access_level)
      end

      before do
        allow(tag).to receive(:protection_rule).and_return(protection_rule)
      end

      it { is_expected.to send(expected_result, :destroy_container_image) }
    end

    context 'for admin', :enable_admin_mode do
      let(:user) { build_stubbed(:admin) }

      it { expect_allowed(:destroy_container_image) }
    end

    context 'for owner' do
      before_all do
        project.add_owner(user)
      end

      context 'when tag has no protection rule' do
        it { expect_allowed(:destroy_container_image) }
      end

      context 'when tag has protection rule' do
        where(:minimum_access_level, :expected_result) do
          Gitlab::Access::ADMIN      | :be_disallowed
          Gitlab::Access::OWNER      | :be_allowed
          Gitlab::Access::MAINTAINER | :be_allowed
        end

        with_them do
          it_behaves_like 'matching expected result with protection rules'
        end
      end
    end

    context 'for maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      context 'when tag has no protection rule' do
        it { expect_allowed(:destroy_container_image) }
      end

      context 'when tag has protection rule' do
        where(:minimum_access_level, :expected_result) do
          Gitlab::Access::ADMIN      | :be_disallowed
          Gitlab::Access::OWNER      | :be_disallowed
          Gitlab::Access::MAINTAINER | :be_allowed
        end

        with_them do
          it_behaves_like 'matching expected result with protection rules'
        end
      end
    end

    context 'for developer' do
      before_all do
        project.add_developer(user)
      end

      context 'when tag has no protection rule' do
        it { expect_allowed(:destroy_container_image) }
      end

      context 'when tag has protection rule' do
        where(:minimum_access_level, :expected_result) do
          Gitlab::Access::ADMIN      | :be_disallowed
          Gitlab::Access::OWNER      | :be_disallowed
          Gitlab::Access::MAINTAINER | :be_disallowed
        end

        with_them do
          it_behaves_like 'matching expected result with protection rules'
        end
      end
    end
  end
end
