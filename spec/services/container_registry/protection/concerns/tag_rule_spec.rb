# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::Concerns::TagRule, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  # Create a test class that includes our service concern
  let(:test_class) do
    Class.new do
      include ContainerRegistry::Protection::Concerns::TagRule

      # Make the private methods public for testing
      public :protected_patterns_for_delete, :protected_for_delete?
    end
  end

  # Create an instance of the test class to use in our tests
  let(:service) { test_class.new }
  let_it_be(:current_user) { create(:user) }

  describe '#protected_patterns_for_delete' do
    let_it_be(:project) { create(:project) }

    subject(:tag_name_patterns) { service.protected_patterns_for_delete(project:, current_user:) }

    context 'when the project has no tag protection rules' do
      it { is_expected.to be_nil }
    end

    context 'when the project has tag protection rules' do
      def create_rule(access_level, tag_name_pattern)
        create(
          :container_registry_protection_tag_rule,
          project: project,
          tag_name_pattern: tag_name_pattern,
          minimum_access_level_for_delete: access_level
        )
      end

      let_it_be(:rule1) { create_rule(:owner, 'owner_pattern') }
      let_it_be(:rule2) { create_rule(:admin, 'admin_pattern') }
      let_it_be(:rule3) { create_rule(:maintainer, 'maintainer_pattern') }

      context 'when current user is nil' do
        let_it_be(:current_user) { nil }
        let(:expected_tag_name_pattern) { [rule1, rule2, rule3].map(&:tag_name_pattern) }

        it 'returns all tag rules' do
          expect(tag_name_patterns.all?(Gitlab::UntrustedRegexp)).to be(true)
          expect(tag_name_patterns.map(&:source)).to match_array(expected_tag_name_pattern)
        end
      end

      context 'when current user is supplied' do
        context 'when current user is an admin', :enable_admin_mode do
          let(:current_user) { build_stubbed(:admin) }

          it { is_expected.to be_nil }
        end

        where(:user_role, :expected_patterns) do
          :developer   | %w[admin_pattern maintainer_pattern owner_pattern]
          :maintainer  | %w[admin_pattern owner_pattern]
          :owner       | %w[admin_pattern]
        end

        with_them do
          before do
            project.send(:"add_#{user_role}", current_user)
          end

          it 'returns the tag name patterns with access levels that are above the user' do
            expect(tag_name_patterns.all?(Gitlab::UntrustedRegexp)).to be(true)
            expect(tag_name_patterns.map(&:source)).to match_array(expected_patterns)
          end
        end
      end
    end
  end

  describe '#protected_for_delete?' do
    let_it_be_with_refind(:project) { create(:project) }

    subject(:protected_by_rules) { service.protected_for_delete?(project:, current_user:) }

    shared_examples 'checking for mutable tag rules' do
      context 'when project has matching mutable tag rules for delete and access level' do
        before_all do
          create(:container_registry_protection_tag_rule, tag_name_pattern: 'b',
            minimum_access_level_for_delete: :owner, project: project)
        end

        where(:user_role, :protected_from_delete_with_tags) do
          :guest      | true
          :reporter   | true
          :developer  | true
          :maintainer | true
          :owner      | false
          :admin      | false
        end

        with_them do
          before do
            if user_role == :admin
              allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
            else
              project.send(:"add_#{user_role}", current_user)
            end
          end

          context 'when the project has container registry tags' do
            before do
              allow(project).to receive(:has_container_registry_tags?).and_return(true)
            end

            it { is_expected.to be(protected_from_delete_with_tags) }
          end

          context 'when project has no container registry tags' do
            before do
              allow(project).to receive(:has_container_registry_tags?).and_return(false)
            end

            it { is_expected.to be(false) }
          end
        end
      end

      context 'when project has no matching tag rules for delete and access level' do
        before do
          allow(project).to receive(:has_container_registry_tags?).and_return(true)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when project has immutable tag rules' do
      before_all do
        create(:container_registry_protection_tag_rule, :immutable, tag_name_pattern: 'a', project: project)
      end

      context 'when project has container registry tags' do
        before do
          allow(project).to receive(:has_container_registry_tags?).and_return(true)
        end

        it { is_expected.to be(true) }

        context 'when current_user is an admin', :enable_admin_mode do
          let(:current_user) { build_stubbed(:admin) }

          it { is_expected.to be(true) }
        end
      end

      context 'when project has no container registry tags' do
        before do
          allow(project).to receive(:has_container_registry_tags?).and_return(false)
        end

        it { is_expected.to be(false) }
      end

      context 'when immutable tags feature flag is disabled' do
        before do
          stub_feature_flags(container_registry_immutable_tags: false)
        end

        it_behaves_like 'checking for mutable tag rules'
      end
    end

    context 'when project has no immutable tag rules' do
      before do
        allow(project).to receive(:has_container_registry_tags?).and_return(true)
      end

      it_behaves_like 'checking for mutable tag rules'
    end
  end
end
