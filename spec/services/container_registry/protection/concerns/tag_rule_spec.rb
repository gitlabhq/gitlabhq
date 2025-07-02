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

      before_all do
        create_rule(:owner, 'owner_pattern')
        create_rule(:admin, 'admin_pattern')
        create_rule(:maintainer, 'maintainer_pattern')
      end

      context 'when current user is nil' do
        let_it_be(:current_user) { nil }

        it 'returns all tag rules' do
          expect(tag_name_patterns).to all(be_a(Gitlab::UntrustedRegexp))
          expect(tag_name_patterns.map(&:source)).to match_array(%w[owner_pattern admin_pattern maintainer_pattern])
        end
      end

      context 'when current user is supplied' do
        context 'when current user is an admin', :enable_admin_mode do
          let(:current_user) { build_stubbed(:admin) }

          it 'does not return anything' do
            expect(tag_name_patterns).to be_nil
          end
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
            expect(tag_name_patterns).to all(be_a(Gitlab::UntrustedRegexp))
            expect(tag_name_patterns.map(&:source)).to match_array(expected_patterns)
          end
        end
      end
    end
  end

  describe '#protected_for_delete?' do
    let_it_be_with_refind(:project) { create(:project) }

    subject(:protected_by_rules) { service.protected_for_delete?(project:, current_user:) }

    it_behaves_like 'checking for mutable tag rules'
  end
end
