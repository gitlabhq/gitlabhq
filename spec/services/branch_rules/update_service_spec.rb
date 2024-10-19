# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::UpdateService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, guest_of: project) }
  let_it_be(:deploy_key_id) { create(:deploy_key, user: user, write_access_to: project).id }
  let_it_be(:protected_branch, reload: true) { create(:protected_branch, project: project) }

  describe '#execute' do
    let!(:allow_force_push) { !protected_branch.allow_force_push }

    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
    let(:ability_allowed) { true }
    let(:new_name) { 'new_name' }
    let(:skip_authorization) { false }
    let(:push_access_levels) { [{ access_level: 0 }, { deploy_key_id: deploy_key_id }] }
    let(:merge_access_levels) { [{ access_level: 0 }] }
    let(:params) do
      {
        name: new_name,
        branch_protection: {
          allow_force_push: allow_force_push,
          push_access_levels: push_access_levels,
          merge_access_levels: merge_access_levels
        }
      }
    end

    subject(:execute) do
      described_class.new(branch_rule, user, params).execute(skip_authorization: skip_authorization)
    end

    before do
      allow(Ability).to receive(:allowed?).and_return(true)
      allow(Ability).to receive(:allowed?)
        .with(user, :update_branch_rule, branch_rule)
        .and_return(ability_allowed)
    end

    context 'when the current_user cannot update the branch rule' do
      let(:ability_allowed) { false }

      it 'raises an access denied error' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end

      context 'and skip_authorization is true' do
        let(:skip_authorization) { true }

        it 'raises an access denied error' do
          expect { execute }.not_to raise_error
        end
      end
    end

    context 'when branch_rule is a Projects::BranchRule' do
      let(:update_service) { ProtectedBranches::UpdateService }
      let(:update_service_instance) { instance_double(update_service) }

      it 'updates the ProtectedBranch and returns a success response', :aggregate_failures do
        expect(execute).to be_success
        expect(protected_branch.reload.name).to eq(new_name)
        expect(protected_branch.allow_force_push).to eq(allow_force_push)
        expect(protected_branch.merge_access_levels.count).to eq(1)
        expect(protected_branch.merge_access_levels.first.access_level).to eq(0)
        expect(protected_branch.push_access_levels.count).to eq(2)
        expect(protected_branch.push_access_levels.first.access_level).to eq(0)
        expect(protected_branch.push_access_levels.last.deploy_key_id).to eq(deploy_key_id)
      end

      context 'if the update fails' do
        let(:errors) { ["Error 1", "Error 2"] }

        before do
          allow(update_service).to receive(:new).and_return(update_service_instance)
          allow(update_service_instance).to receive(:execute).and_return(protected_branch)
          allow(protected_branch).to receive_message_chain(:errors, :any?).and_return(errors)
          allow(protected_branch).to receive_message_chain(:errors, :full_messages).and_return(errors)
        end

        it 'returns an error', :aggregate_failures do
          expect(response = execute).to be_error
          expect(response[:message]).to eq(errors)
        end
      end

      context 'when unpermitted params are provided' do
        let(:params) { { name: new_name, not_permitted: 'not_permitted' } }

        it 'removes them' do
          expect(update_service).to receive(:new).with(project, user, { name: new_name }).and_call_original
          execute
        end
      end

      context 'when name is invalid' do
        let(:new_name) { nil }

        it 'returns a validation error' do
          expect(response = execute).to be_error
          expect(response[:message]).to match_array(["Name can't be blank"])
        end
      end

      context 'when access levels are invalid' do
        let(:push_access_levels) { [{ access_level: 123 }] }
        let(:merge_access_levels) { [{ access_level: 123 }] }

        it 'returns a validation error' do
          expect(response = execute).to be_error
          expect(response[:message]).to match_array([
            "Merge access levels access level is not included in the list",
            "Push access levels access level is not included in the list"
          ])
        end
      end

      context 'when branch_protection.allow_force_push is null' do
        let(:allow_force_push) { nil }

        # TODO: We should be validating
        # ProtectedBranch#allow_force_push is not null instead of
        # relying on db constraints
        it 'raises a not null violation error' do
          expect { execute }.to raise_error(ActiveRecord::NotNullViolation)
        end
      end

      context 'when access levels already exist' do
        before do
          create(
            :protected_branch_push_access_level,
            protected_branch: protected_branch,
            deploy_key: create(:deploy_key, user: create(:user, guest_of: project), write_access_to: project)
          )
        end

        it 'treats params as definitive list of access levels', :aggregate_failures do
          expect(protected_branch.merge_access_levels.count).to eq(1)
          expect(protected_branch.merge_access_levels.first.access_level).not_to eq(0)
          expect(protected_branch.push_access_levels.count).to eq(2)
          expect(protected_branch.push_access_levels.first.access_level).not_to eq(0)
          expect(protected_branch.push_access_levels.last.deploy_key_id).not_to eq(deploy_key_id)

          expect(execute).to be_success

          expect(protected_branch.merge_access_levels.count).to eq(1)
          expect(protected_branch.merge_access_levels.first.access_level).to eq(0)
          expect(protected_branch.push_access_levels.count).to eq(2)
          expect(protected_branch.push_access_levels.first.access_level).to eq(0)
          expect(protected_branch.push_access_levels.last.deploy_key_id).to eq(deploy_key_id)
        end
      end
    end

    context 'when branch_rule is a ProtectedBranch' do
      let(:branch_rule) { protected_branch }

      it 'returns an error' do
        expect(response = execute).to be_error
        expect(response[:message]).to eq('Unknown branch rule type.')
      end
    end
  end
end
