# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepositoryPolicy, feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, creator: user) }
  let_it_be_with_reload(:container_repository) { create(:container_repository, project: project) }

  subject { described_class.new(user, container_repository) }

  shared_examples 'not allowing anonymous user' do
    context 'when the current user is anonymous' do
      let(:user) { nil }

      it { is_expected.to be_disallowed(:destroy_container_image) }
    end
  end

  describe 'destroy_container_image' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(container_repository).to receive(:has_tags?).and_return(has_tags)
    end

    context 'when the project has tag protection rules' do
      before_all do
        create(
          :container_registry_protection_tag_rule,
          project: project,
          minimum_access_level_for_delete: :owner
        )
      end

      context 'when the container repository has tags' do
        let(:has_tags) { true }

        where(:user_role, :expected_result) do
          :owner      | :be_allowed
          :maintainer | :be_disallowed
          :developer  | :be_disallowed
        end

        with_them do
          before do
            project.send(:"add_#{user_role}", user)
          end

          it { is_expected.to send(expected_result, :destroy_container_image) }
        end

        context 'when the current user is an admin', :enable_admin_mode do
          let(:user) { build_stubbed(:admin) }

          it { expect_allowed(:destroy_container_image) }
        end

        it_behaves_like 'not allowing anonymous user'
      end

      context 'when the container repository does not have tags' do
        let(:has_tags) { false }

        %i[owner maintainer developer].each do |user_role|
          context "with the role of #{user_role}" do
            before do
              project.send(:"add_#{user_role}", user)
            end

            it { expect_allowed(:destroy_container_image) }
          end
        end

        it_behaves_like 'not allowing anonymous user'
      end
    end

    context 'when the project does not have tag protection rules' do
      let(:has_tags) { true }

      %i[owner maintainer developer].each do |user_role|
        context "with the role of #{user_role}" do
          before do
            project.send(:"add_#{user_role}", user)
          end

          it { expect_allowed(:destroy_container_image) }
        end
      end

      it_behaves_like 'not allowing anonymous user'
    end
  end
end
