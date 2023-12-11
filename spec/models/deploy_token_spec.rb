# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployToken, feature_category: :continuous_delivery do
  subject(:deploy_token) { create(:deploy_token) }

  it { is_expected.to have_many :project_deploy_tokens }
  it { is_expected.to have_many(:projects).through(:project_deploy_tokens) }
  it { is_expected.to have_many :group_deploy_tokens }
  it { is_expected.to have_many(:groups).through(:group_deploy_tokens) }
  it { is_expected.to belong_to(:user).with_foreign_key('creator_id') }

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    let(:username_format_message) { "can contain only letters, digits, '_', '-', '+', and '.'" }

    it { is_expected.to validate_length_of(:username).is_at_most(255) }
    it { is_expected.to allow_value('GitLab+deploy_token-3.14').for(:username) }
    it { is_expected.not_to allow_value('<script>').for(:username).with_message(username_format_message) }
    it { is_expected.not_to allow_value('').for(:username).with_message(username_format_message) }
    it { is_expected.to validate_presence_of(:deploy_token_type) }
  end

  shared_examples 'invalid group deploy token' do
    context 'revoked' do
      before do
        deploy_token.update_column(:revoked, true)
      end

      it { is_expected.to eq(false) }
    end

    context 'expired' do
      before do
        deploy_token.update!(expires_at: Date.today - 1.month)
      end

      it { is_expected.to eq(false) }
    end

    context 'project type' do
      before do
        deploy_token.update_column(:deploy_token_type, 2)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'deploy_token_type validations' do
    context 'when a deploy token is associated to a group' do
      it 'does not allow setting a project to it' do
        group_token = create(:deploy_token, :group)
        group_token.projects << build(:project)

        expect(group_token).not_to be_valid
        expect(group_token.errors.full_messages).to include('Deploy token cannot have projects assigned')
      end
    end

    context 'when a deploy token is associated to a project' do
      it 'does not allow setting a group to it' do
        project_token = create(:deploy_token)
        project_token.groups << build(:group)

        expect(project_token).not_to be_valid
        expect(project_token.errors.full_messages).to include('Deploy token cannot have groups assigned')
      end
    end
  end

  describe '#ensure_token' do
    it 'ensures a token' do
      deploy_token.token_encrypted = nil
      deploy_token.save!

      expect(deploy_token.token_encrypted).not_to be_empty
    end
  end

  describe '#ensure_at_least_one_scope' do
    context 'with at least one scope' do
      it { is_expected.to be_valid }
    end

    context 'with no scopes' do
      it 'is invalid' do
        deploy_token = build(:deploy_token, read_repository: false, read_registry: false, write_registry: false)

        expect(deploy_token).not_to be_valid
        expect(deploy_token.errors[:base].first).to eq("Scopes can't be blank")
      end
    end
  end

  describe '#valid_for_dependency_proxy?' do
    let_it_be_with_reload(:deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }

    subject { deploy_token.valid_for_dependency_proxy? }

    it { is_expected.to eq(true) }

    it_behaves_like 'invalid group deploy token'

    context 'insufficient scopes' do
      before do
        deploy_token.update_column(:write_registry, false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#has_access_to_group?' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:deploy_token) { create(:deploy_token, :group) }
    let_it_be(:group_deploy_token) { create(:group_deploy_token, group: group, deploy_token: deploy_token) }

    let(:test_group) { group }

    subject { deploy_token.has_access_to_group?(test_group) }

    it { is_expected.to eq(true) }

    it_behaves_like 'invalid group deploy token'

    context 'for a sub group' do
      let(:test_group) { create(:group, parent: group) }

      it { is_expected.to eq(true) }
    end

    context 'for a different group' do
      let(:test_group) { create(:group) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#scopes' do
    context 'with all the scopes' do
      let_it_be(:deploy_token) { create(:deploy_token, :all_scopes) }

      it 'returns scopes assigned to DeployToken' do
        expect(deploy_token.scopes).to eq(DeployToken::AVAILABLE_SCOPES)
      end
    end

    context 'with only one scope' do
      it 'returns scopes assigned to DeployToken' do
        deploy_token = create(:deploy_token, read_registry: false, write_registry: false)
        expect(deploy_token.scopes).to eq([:read_repository])
      end
    end
  end

  describe '#revoke!' do
    it 'updates revoke attribute' do
      deploy_token.revoke!
      expect(deploy_token.revoked?).to be_truthy
    end
  end

  describe "#active?" do
    context "when it has been revoked" do
      it 'returns false' do
        deploy_token.revoke!
        expect(deploy_token.active?).to be_falsy
      end
    end

    context "when it hasn't been revoked and is not expired" do
      it 'returns true' do
        expect(deploy_token.active?).to be_truthy
      end
    end

    context "when it hasn't been revoked and is expired" do
      it 'returns true' do
        deploy_token.update_attribute(:expires_at, Date.today - 5.days)
        expect(deploy_token.active?).to be_falsy
      end
    end

    context "when it hasn't been revoked and has no expiry" do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'returns true' do
        expect(deploy_token.active?).to be_truthy
      end
    end
  end

  # override the default PolicyActor implementation that always returns false
  describe "#deactivated?" do
    context "when it has been revoked" do
      it 'returns true' do
        deploy_token.revoke!

        expect(deploy_token.deactivated?).to be_truthy
      end
    end

    context "when it hasn't been revoked and is not expired" do
      it 'returns false' do
        expect(deploy_token.deactivated?).to be_falsy
      end
    end

    context "when it hasn't been revoked and is expired" do
      it 'returns false' do
        deploy_token.update_attribute(:expires_at, Date.today - 5.days)

        expect(deploy_token.deactivated?).to be_truthy
      end
    end

    context "when it hasn't been revoked and has no expiry" do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'returns false' do
        expect(deploy_token.deactivated?).to be_falsy
      end
    end
  end

  describe '#username' do
    context 'persisted records' do
      it 'returns a default username if none is set' do
        expect(deploy_token.username).to eq("gitlab+deploy-token-#{deploy_token.id}")
      end

      it 'returns the username provided if one is set' do
        deploy_token = create(:deploy_token, username: 'deployer')

        expect(deploy_token.username).to eq('deployer')
      end
    end

    context 'new records' do
      it 'returns nil if no username is set' do
        deploy_token = build(:deploy_token)

        expect(deploy_token.username).to be_nil
      end

      it 'returns the username provided if one is set' do
        deploy_token = build(:deploy_token, username: 'deployer')

        expect(deploy_token.username).to eq('deployer')
      end
    end
  end

  describe '#holder' do
    subject { deploy_token.holder }

    context 'when the token is of project type' do
      it 'returns the relevant holder token' do
        expect(subject).to eq(deploy_token.project_deploy_tokens.first)
      end
    end

    context 'when the token is of group type' do
      let(:group) { create(:group) }
      let(:deploy_token) { create(:deploy_token, :group) }

      it 'returns the relevant holder token' do
        expect(subject).to eq(deploy_token.group_deploy_tokens.first)
      end
    end
  end

  describe '#has_access_to?' do
    let(:project) { create(:project) }

    subject { deploy_token.has_access_to?(project) }

    context 'when a project is not passed in' do
      let(:project) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when a project is passed in' do
      context 'when deploy token is active and related to project' do
        let(:deploy_token) { create(:deploy_token, projects: [project]) }

        it { is_expected.to be_truthy }
      end

      context 'when deploy token is active but not related to project' do
        let(:deploy_token) { create(:deploy_token) }

        it { is_expected.to be_falsy }
      end

      context 'when deploy token is revoked and related to project' do
        let(:deploy_token) { create(:deploy_token, :revoked, projects: [project]) }

        it { is_expected.to be_falsy }
      end

      context 'when deploy token is revoked and not related to the project' do
        let(:deploy_token) { create(:deploy_token, :revoked) }

        it { is_expected.to be_falsy }
      end

      context 'and when the token is of group type' do
        let_it_be(:group) { create(:group) }

        let(:deploy_token) { create(:deploy_token, :group) }

        before do
          deploy_token.groups << group
        end

        context 'and the passed-in project does not belong to any group' do
          it { is_expected.to be_falsy }
        end

        context 'and the passed-in project belongs to the token group' do
          it 'is true' do
            group.projects << project

            is_expected.to be_truthy
          end
        end

        context 'and the passed-in project belongs to a subgroup' do
          let(:child_group) { create(:group, parent_id: group.id) }
          let(:grandchild_group) { create(:group, parent_id: child_group.id) }

          before do
            grandchild_group.projects << project
          end

          context 'and the token group is an ancestor (grand-parent) of this group' do
            it { is_expected.to be_truthy }
          end

          context 'and the token group is not ancestor of this group' do
            let(:child2_group) { create(:group, parent_id: group.id) }

            it 'is false' do
              deploy_token.groups = [child2_group]

              is_expected.to be_falsey
            end
          end
        end

        context 'and the passed-in project does not belong to the token group' do
          it { is_expected.to be_falsy }
        end

        context 'and the project belongs to a group that is parent of the token group' do
          let(:super_group) { create(:group) }
          let(:deploy_token) { create(:deploy_token, :group) }
          let(:group) { create(:group, parent_id: super_group.id) }

          it 'is false' do
            super_group.projects << project

            is_expected.to be_falsey
          end
        end
      end

      context 'and the token is of project type' do
        let(:deploy_token) { create(:deploy_token, projects: [project]) }

        context 'and the passed-in project is the same as the token project' do
          it { is_expected.to be_truthy }
        end

        context 'and the passed-in project is not the same as the token project' do
          subject { deploy_token.has_access_to?(create(:project)) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#expires_at' do
    context 'when using Forever.date' do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'returns nil' do
        expect(deploy_token.expires_at).to be_nil
      end
    end

    context 'when using a personalized date' do
      let(:expires_at) { Date.today + 5.months }
      let(:deploy_token) { create(:deploy_token, expires_at: expires_at) }

      it 'returns the personalized date' do
        expect(deploy_token.expires_at).to eq(expires_at)
      end
    end
  end

  describe '#expires_at=' do
    context 'when passing nil' do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'assigns Forever.date' do
        expect(deploy_token.read_attribute(:expires_at)).to eq(Forever.date)
      end
    end

    context 'when passing a value' do
      let(:expires_at) { Date.today + 5.months }
      let(:deploy_token) { create(:deploy_token, expires_at: expires_at) }

      it 'respects the value' do
        expect(deploy_token.read_attribute(:expires_at)).to eq(expires_at)
      end
    end
  end

  describe '.gitlab_deploy_token' do
    let(:project) { create(:project) }

    subject { project.deploy_tokens.gitlab_deploy_token }

    context 'with a gitlab deploy token associated' do
      it 'returns the gitlab deploy token' do
        deploy_token = create(:deploy_token, :gitlab_deploy_token, projects: [project])
        is_expected.to eq(deploy_token)
      end
    end

    context 'with no gitlab deploy token associated' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#accessible_projects' do
    subject { deploy_token.accessible_projects }

    context 'when a deploy token is associated to a project' do
      let_it_be(:deploy_token) { create(:deploy_token, :project) }

      it 'returns only projects directly associated with the token' do
        expect(deploy_token).to receive(:projects)

        subject
      end
    end

    context 'when a deploy token is associated to a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [group]) }

      it 'returns all projects from the group' do
        expect(group).to receive(:all_projects)

        subject
      end
    end
  end

  describe '.impersonated?' do
    it 'returns false' do
      expect(subject.impersonated?).to be(false)
    end
  end

  describe '.token' do
    # Specify a blank token_encrypted so that the model's method is used
    # instead of the factory value
    subject(:plaintext) { create(:deploy_token, token_encrypted: nil).token }

    it { is_expected.to match(/gldt-[A-Za-z0-9_-]{20}/) }
  end
end
