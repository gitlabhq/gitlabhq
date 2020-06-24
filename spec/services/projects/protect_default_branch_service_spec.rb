# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectDefaultBranchService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project) }

  describe '#execute' do
    before do
      allow(service)
        .to receive(:protect_default_branch)
    end

    context 'without a default branch' do
      it 'does nothing' do
        allow(service)
          .to receive(:default_branch)
          .and_return(nil)

        service.execute

        expect(service)
          .not_to have_received(:protect_default_branch)
      end
    end

    context 'with a default branch' do
      it 'protects the default branch' do
        allow(service)
          .to receive(:default_branch)
          .and_return('master')

        service.execute

        expect(service)
          .to have_received(:protect_default_branch)
      end
    end
  end

  describe '#protect_default_branch' do
    before do
      allow(service)
        .to receive(:default_branch)
        .and_return('master')

      allow(project)
        .to receive(:change_head)
        .with('master')

      allow(service)
        .to receive(:create_protected_branch)
    end

    context 'when branch protection is needed' do
      before do
        allow(service)
          .to receive(:protect_branch?)
          .and_return(true)

        allow(service)
          .to receive(:create_protected_branch)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'protects the default branch' do
        service.protect_default_branch

        expect(service)
          .to have_received(:create_protected_branch)
      end
    end

    context 'when branch protection is not needed' do
      before do
        allow(service)
          .to receive(:protect_branch?)
          .and_return(false)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'does not protect the default branch' do
        service.protect_default_branch

        expect(service)
          .not_to have_received(:create_protected_branch)
      end
    end
  end

  describe '#create_protected_branch' do
    it 'creates the protected branch' do
      creator = instance_spy(User)
      create_service = instance_spy(ProtectedBranches::CreateService)
      access_level = Gitlab::Access::DEVELOPER
      params = {
        name: 'master',
        push_access_levels_attributes: [{ access_level: access_level }],
        merge_access_levels_attributes: [{ access_level: access_level }]
      }

      allow(project)
        .to receive(:creator)
        .and_return(creator)

      allow(ProtectedBranches::CreateService)
        .to receive(:new)
        .with(project, creator, params)
        .and_return(create_service)

      allow(service)
        .to receive(:push_access_level)
        .and_return(access_level)

      allow(service)
        .to receive(:merge_access_level)
        .and_return(access_level)

      allow(service)
        .to receive(:default_branch)
        .and_return('master')

      allow(create_service)
        .to receive(:execute)
        .with(skip_authorization: true)

      service.create_protected_branch

      expect(create_service)
        .to have_received(:execute)
    end
  end

  describe '#protect_branch?' do
    context 'when default branch protection is disabled' do
      it 'returns false' do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_NONE)

        expect(service.protect_branch?).to eq(false)
      end
    end

    context 'when default branch protection is enabled' do
      before do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        allow(service)
          .to receive(:default_branch)
          .and_return('master')
      end

      it 'returns false if the branch is already protected' do
        allow(ProtectedBranch)
          .to receive(:protected?)
          .with(project, 'master')
          .and_return(true)

        expect(service.protect_branch?).to eq(false)
      end

      it 'returns true if the branch is not yet protected' do
        allow(ProtectedBranch)
          .to receive(:protected?)
          .with(project, 'master')
          .and_return(false)

        expect(service.protect_branch?).to eq(true)
      end
    end
  end

  describe '#default_branch' do
    it 'returns the default branch of the project' do
      allow(project)
        .to receive(:default_branch)
        .and_return('master')

      expect(service.default_branch).to eq('master')
    end
  end

  describe '#push_access_level' do
    context 'when developers can push' do
      it 'returns the DEVELOPER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(service.push_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when developers can not push' do
      it 'returns the MAINTAINER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(service.push_access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#merge_access_level' do
    context 'when developers can merge' do
      it 'returns the DEVELOPER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(service.merge_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when developers can not merge' do
      it 'returns the MAINTAINER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection)
          .and_return(Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(service.merge_access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end
end
