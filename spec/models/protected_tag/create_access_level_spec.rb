# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag::CreateAccessLevel, feature_category: :source_code_management do
  include_examples 'protected tag access'

  describe 'associations' do
    it { is_expected.to belong_to(:deploy_key) }
  end

  describe 'validations', :aggregate_failures do
    let_it_be(:protected_tag) { create(:protected_tag) }

    context 'when deploy key enabled for the project' do
      let(:deploy_key) { create(:deploy_key, projects: [protected_tag.project]) }

      it 'is valid' do
        level = build(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)

        expect(level).to be_valid
      end
    end

    context 'when a record exists with the same access level' do
      before do
        create(:protected_tag_create_access_level, protected_tag: protected_tag)
      end

      it 'is not valid' do
        level = build(:protected_tag_create_access_level, protected_tag: protected_tag)

        expect(level).to be_invalid
        expect(level.errors.full_messages).to include('Access level has already been taken')
      end
    end

    context 'when a deploy key already added for this access level' do
      let!(:create_access_level) do
        create(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)
      end

      let(:deploy_key) { create(:deploy_key, projects: [protected_tag.project]) }

      it 'is not valid' do
        level = build(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)

        expect(level).to be_invalid
        expect(level.errors.full_messages).to contain_exactly('Deploy key has already been taken')
      end
    end

    context 'when deploy key is not enabled for the project' do
      let(:create_access_level) do
        build(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: create(:deploy_key))
      end

      it 'returns an error' do
        expect(create_access_level).to be_invalid
        expect(create_access_level.errors.full_messages).to contain_exactly(
          'Deploy key is not enabled for this project'
        )
      end
    end
  end

  describe '#check_access' do
    let_it_be(:project) { create(:project) }
    let_it_be(:protected_tag) { create(:protected_tag, :no_one_can_create, project: project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:deploy_key) { create(:deploy_key, user: user) }

    let!(:deploy_keys_project) do
      create(:deploy_keys_project, project: project, deploy_key: deploy_key, can_push: can_push)
    end

    let(:create_access_level) { protected_tag.create_access_levels.first }
    let(:can_push) { true }

    before_all do
      project.add_maintainer(user)
    end

    it { expect(create_access_level.check_access(user)).to be_falsey }

    context 'when this create_access_level is tied to a deploy key' do
      let(:create_access_level) do
        create(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)
      end

      context 'when the deploy key is among the active keys for this project' do
        it { expect(create_access_level.check_access(user)).to be_truthy }
      end

      context 'when user is missing' do
        it { expect(create_access_level.check_access(nil)).to be_falsey }
      end

      context 'when deploy key does not belong to the user' do
        let(:another_user) { create(:user) }

        it { expect(create_access_level.check_access(another_user)).to be_falsey }
      end

      context 'when user cannot access the project' do
        before do
          allow(user).to receive(:can?).with(:read_project, project).and_return(false)
        end

        it { expect(create_access_level.check_access(user)).to be_falsey }
      end

      context 'when the deploy key is not among the active keys of this project' do
        let(:can_push) { false }

        it { expect(create_access_level.check_access(user)).to be_falsey }
      end
    end
  end

  describe '#type' do
    let(:create_access_level) { build(:protected_tag_create_access_level) }

    it 'returns :role by default' do
      expect(create_access_level.type).to eq(:role)
    end

    context 'when a deploy key is tied to the protected branch' do
      let(:create_access_level) { build(:protected_tag_create_access_level, deploy_key: build(:deploy_key)) }

      it 'returns :deploy_key' do
        expect(create_access_level.type).to eq(:deploy_key)
      end
    end
  end
end
