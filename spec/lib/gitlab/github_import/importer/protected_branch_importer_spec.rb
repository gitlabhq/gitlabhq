# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ProtectedBranchImporter do
  subject(:importer) { described_class.new(github_protected_branch, project, client) }

  let(:allow_force_pushes_on_github) { true }
  let(:github_protected_branch) do
    Gitlab::GithubImport::Representation::ProtectedBranch.new(
      id: 'protection',
      allow_force_pushes: allow_force_pushes_on_github
    )
  end

  let(:project) { create(:project, :repository) }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  describe '#execute' do
    let(:create_service) { instance_double('ProtectedBranches::CreateService') }

    shared_examples 'create branch protection by the strictest ruleset' do
      let(:expected_ruleset) do
        {
          name: 'protection',
          push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
          allow_force_push: expected_allow_force_push
        }
      end

      it 'calls service with the correct arguments' do
        expect(ProtectedBranches::CreateService).to receive(:new).with(
          project,
          project.creator,
          expected_ruleset
        ).and_return(create_service)

        expect(create_service).to receive(:execute).with(skip_authorization: true)
        importer.execute
      end

      it 'creates protected branch and access levels for given github rule' do
        expect { importer.execute }.to change(ProtectedBranch, :count).by(1)
          .and change(ProtectedBranch::PushAccessLevel, :count).by(1)
          .and change(ProtectedBranch::MergeAccessLevel, :count).by(1)
      end
    end

    context 'when branch is protected on GitLab' do
      before do
        create(
          :protected_branch,
          project: project,
          name: 'protect*',
          allow_force_push: allow_force_pushes_on_gitlab
        )
      end

      context 'when branch protection rule on Gitlab is stricter than on Github' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { false }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rule on Github is stricter than on Gitlab' do
        let(:allow_force_pushes_on_github) { false }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rules on Github and Gitlab are the same' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { true }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end

    context 'when branch is not protected on GitLab' do
      let(:expected_allow_force_push) { true }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end
  end
end
