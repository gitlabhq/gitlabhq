# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DeployKeyAccess, feature_category: :source_code_management do
  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be(:deploy_key) { create(:deploy_key, :owned, write_access_to: project) }

  subject(:access) { described_class.new(deploy_key, container: project) }

  before_all do
    project.add_developer(deploy_key.user)
  end

  describe '#can_create_tag?' do
    let_it_be(:protected_tag) { create(:protected_tag, :no_one_can_create, project: project, name: 'v*') }

    context 'when no-one can create tag' do
      it 'returns false' do
        expect(access.can_create_tag?('v0.1.2')).to be_falsey
      end
    end

    context 'push tag that matches a protected tag pattern via a deploy key' do
      before do
        create(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)
      end

      it 'allows to push the tag' do
        expect(access.can_create_tag?('v0.1.2')).to be_truthy
      end
    end
  end

  describe '#can_push_for_ref?' do
    let_it_be(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project) }

    subject(:can_push_for_ref) { access.can_push_for_ref?(protected_branch.name) }

    it { is_expected.to be_falsey }

    context 'when the deploy_key is active for the project' do
      before do
        create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)
      end

      it { is_expected.to be_truthy }

      context 'but the deploy key user cannot read the project' do
        before do
          deploy_key.user = build(:user)
        end

        it { is_expected.to be_falsey }
      end
    end
  end
end
