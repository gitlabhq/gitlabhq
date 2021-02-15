# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedRef do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }

  where(:klass, :factory, :action) do
    ProtectedBranch | :protected_branch | :push
    ProtectedTag    | :protected_tag | :create
  end

  with_them do
    describe '#protected_ref_accessible_to?' do
      subject do
        klass.protected_ref_accessible_to?('release', user, project: project, action: action)
      end

      it 'user cannot do action if rules do not exist' do
        is_expected.to be_falsy
      end

      context 'the ref is protected' do
        let!(:default_rule) { create(factory, :"developers_can_#{action}", project: project, name: 'release') }

        context 'all rules permit action' do
          let!(:maintainers_can) { create(factory, :"maintainers_can_#{action}", project: project, name: 'release*') }

          it 'user can do action' do
            is_expected.to be_truthy
          end
        end

        context 'one of the rules forbids action' do
          let!(:no_one_can) { create(factory, :"no_one_can_#{action}", project: project, name: 'release*') }

          it 'user cannot do action' do
            is_expected.to be_falsy
          end
        end
      end
    end

    describe '#developers_can?' do
      subject do
        klass.developers_can?(action, 'release')
      end

      it 'developers cannot do action if rules do not exist' do
        is_expected.to be_falsy
      end

      context 'the ref is protected' do
        let!(:default_rule) { create(factory, :"developers_can_#{action}", project: project, name: 'release') }

        context 'all rules permit developers to do action' do
          let!(:developers_can) { create(factory, :"developers_can_#{action}", project: project, name: 'release*') }

          it 'developers can do action' do
            is_expected.to be_truthy
          end
        end

        context 'one of the rules forbids developers to do action' do
          let!(:maintainers_can) { create(factory, :"maintainers_can_#{action}", project: project, name: 'release*') }

          it 'developers cannot do action' do
            is_expected.to be_falsy
          end
        end
      end
    end
  end
end
