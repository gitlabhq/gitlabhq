# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::EditScopeValidations, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let(:test_class) do
    Class.new(::BaseService) do
      include Ci::JobTokenScope::EditScopeValidations
    end
  end

  let_it_be(:source_project) { create(:project) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:target_group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  subject(:test_instance) { test_class.new(source_project, current_user) }

  describe '#validate_source_project_and_target_project_access!' do
    subject(:validate_source_project_and_target_project_access) do
      test_instance.validate_source_project_and_target_project_access!(source_project, target_project, current_user)
    end

    before do
      source_project.send("add_#{source_project_user_role}", current_user) if source_project_user_role
      target_project.send("add_#{target_project_user_role}", current_user) if target_project_user_role
      source_project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(source_project_visibility, false))
      target_project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(target_project_visibility, false))
    end

    context 'when all permissions are in order' do
      where(:source_project_visibility,
        :target_project_visibility,
        :source_project_user_role,
        :target_project_user_role) do
        'PUBLIC' | 'PUBLIC' | :maintainer | :developer
        'PUBLIC' | 'PUBLIC' | :maintainer | :guest
        'PRIVATE' | 'PRIVATE' | :maintainer | :developer
        'PRIVATE' | 'PRIVATE' | :maintainer | :guest
      end

      with_them do
        it 'passes the validation' do
          expect do
            validate_source_project_and_target_project_access
          end.not_to raise_error
        end
      end
    end

    context 'when user lacks admin_project permissions for the source project' do
      where(:source_project_visibility,
        :target_project_visibility,
        :source_project_user_role,
        :target_project_user_role) do
        'PUBLIC' | 'PUBLIC' | nil | :developer
        'PRIVATE' | 'PRIVATE' | nil | :developer
        'PUBLIC' | 'PUBLIC' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :developer | :developer
        'PUBLIC' | 'PRIVATE' | :developer | :developer
      end

      with_them do
        it 'raises an error' do
          expect do
            validate_source_project_and_target_project_access
          end.to raise_error(Ci::JobTokenScope::EditScopeValidations::ValidationError,
            'Insufficient permissions to modify the job token scope')
        end
      end
    end

    context 'when user lacks read_project permissions for the target project' do
      where(:source_project_visibility,
        :target_project_visibility,
        :source_project_user_role,
        :target_project_user_role) do
        'PRIVATE' | 'PRIVATE' | :maintainer | nil
        'PUBLIC' | 'PRIVATE' | :maintainer | nil
      end

      with_them do
        it 'raises an error' do
          expect do
            validate_source_project_and_target_project_access
          end.to raise_error(Ci::JobTokenScope::EditScopeValidations::ValidationError,
            Ci::JobTokenScope::EditScopeValidations::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND)
        end
      end
    end
  end

  describe '#validate_source_project_and_target_group_access!' do
    subject(:validate_source_project_and_target_group_access) do
      test_instance.validate_source_project_and_target_group_access!(source_project, target_group, current_user)
    end

    before do
      source_project.send("add_#{source_project_user_role}", current_user) if source_project_user_role
      target_group.send("add_#{target_group_user_role}", current_user) if target_group_user_role
      source_project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(source_project_visibility, false))
      target_group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(target_group_visibility, false))
    end

    context 'when all permissions are in order' do
      where(:source_project_visibility,
        :target_group_visibility,
        :source_project_user_role,
        :target_group_user_role) do
        'PUBLIC' | 'PUBLIC' | :maintainer | :developer
        'PUBLIC' | 'PUBLIC' | :maintainer | :guest
        'PRIVATE' | 'PRIVATE' | :maintainer | :developer
        'PRIVATE' | 'PRIVATE' | :maintainer | :guest
      end

      with_them do
        it 'passes the validation' do
          expect do
            validate_source_project_and_target_group_access
          end.not_to raise_error
        end
      end
    end

    context 'when user lacks admin_project permissions for the source project' do
      where(:source_project_visibility,
        :target_group_visibility,
        :source_project_user_role,
        :target_group_user_role) do
        'PUBLIC' | 'PUBLIC' | nil | :developer
        'PRIVATE' | 'PRIVATE' | nil | :developer
        'PUBLIC' | 'PUBLIC' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :developer | :developer
        'PUBLIC' | 'PRIVATE' | :developer | :developer
      end

      with_them do
        it 'raises an error' do
          expect do
            validate_source_project_and_target_group_access
          end.to raise_error(Ci::JobTokenScope::EditScopeValidations::ValidationError,
            'Insufficient permissions to modify the job token scope')
        end
      end
    end

    context 'when user lacks read_project permissions for the target group' do
      where(:source_project_visibility,
        :target_group_visibility,
        :source_project_user_role,
        :target_group_user_role) do
        'PRIVATE' | 'PRIVATE' | :maintainer | nil
        'PUBLIC' | 'PRIVATE' | :maintainer | nil
      end

      with_them do
        it 'raises an error' do
          expect do
            validate_source_project_and_target_group_access
          end.to raise_error(Ci::JobTokenScope::EditScopeValidations::ValidationError,
            Ci::JobTokenScope::EditScopeValidations::TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND)
        end
      end
    end
  end

  describe '#validate_group_remove!' do
    subject(:validate_group_execution) do
      test_instance.validate_group_remove!(source_project, current_user)
    end

    before do
      source_project.send("add_#{source_project_user_role}", current_user) if source_project_user_role
      target_group.send("add_#{target_group_user_role}", current_user) if target_group_user_role
      source_project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(source_project_visibility, false))
      target_group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(target_group_visibility, false))
    end

    context 'when all permissions are in order' do
      where(:source_project_visibility,
        :target_group_visibility,
        :source_project_user_role,
        :target_group_user_role) do
        'PUBLIC' | 'PUBLIC' | :maintainer | :developer
        'PUBLIC' | 'PUBLIC' | :maintainer | :guest
        'PRIVATE' | 'PRIVATE' | :maintainer | :developer
        'PRIVATE' | 'PRIVATE' | :maintainer | :guest
        'PUBLIC' | 'PUBLIC' | :maintainer | nil
        'PUBLIC' | 'PUBLIC' | :maintainer | nil
        'PRIVATE' | 'PRIVATE' | :maintainer | nil
        'PRIVATE' | 'PRIVATE' | :maintainer | nil
      end

      with_them do
        it 'passes the validation' do
          expect do
            validate_group_execution
          end.not_to raise_error
        end
      end
    end

    context 'when user lacks admin_project permissions for the source project' do
      where(:source_project_visibility,
        :target_group_visibility,
        :source_project_user_role,
        :target_group_user_role) do
        'PUBLIC' | 'PUBLIC' | nil | :developer
        'PRIVATE' | 'PRIVATE' | nil | :developer
        'PUBLIC' | 'PUBLIC' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :guest | :developer
        'PRIVATE' | 'PRIVATE' | :developer | :developer
        'PUBLIC' | 'PRIVATE' | :developer | :developer
      end

      with_them do
        it 'raises an error' do
          expect do
            validate_group_execution
          end.to raise_error(Ci::JobTokenScope::EditScopeValidations::ValidationError,
            'Insufficient permissions to modify the job token scope')
        end
      end
    end
  end

  describe '#validate_target_exists!' do
    subject(:validate_target_exists_execution) do
      test_instance.validate_target_exists!(target)
    end

    context 'when target is nil' do
      let_it_be(:target) { nil }

      it 'raises an error' do
        expect do
          validate_target_exists_execution
        end.to raise_error(Ci::JobTokenScope::EditScopeValidations::NotFoundError,
          Ci::JobTokenScope::EditScopeValidations::TARGET_DOES_NOT_EXIST)
      end
    end

    context 'when target is present' do
      let_it_be(:target) { target_project }

      it 'raises an error' do
        expect do
          validate_target_exists_execution
        end.not_to raise_error
      end
    end
  end
end
