# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Submodules::UpdateService do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user, :commit_email) }
  let(:branch_name) { project.default_branch }
  let(:submodule) { 'six' }
  let(:commit_sha) { 'e25eda1fece24ac7a03624ed1320f82396f35bd8' }
  let(:commit_message) { 'whatever' }
  let(:current_sha) { repository.blob_at('HEAD', submodule).id }
  let(:commit_params) do
    {
      submodule: submodule,
      commit_message: commit_message,
      commit_sha: commit_sha,
      branch_name: branch_name
    }
  end

  subject { described_class.new(project, user, commit_params) }

  describe "#execute" do
    shared_examples 'returns error result' do
      it do
        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq error_message
      end
    end

    context 'when the user is not authorized' do
      it_behaves_like 'returns error result' do
        let(:error_message) { 'You are not allowed to push into this branch' }
      end
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when the branch is protected' do
        before do
          create(:protected_branch, :no_one_can_push, project: project, name: branch_name)
        end

        it_behaves_like 'returns error result' do
          let(:error_message) { 'You are not allowed to push into this branch' }
        end
      end

      context 'validations' do
        context 'when submodule' do
          context 'is empty' do
            let(:submodule) { '' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'is not present' do
            let(:submodule) { nil }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'is invalid' do
            let(:submodule) { 'VERSION' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid submodule path' }
            end
          end

          context 'does not exist' do
            let(:submodule) { 'non-existent-submodule' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid submodule path' }
            end
          end

          context 'has traversal path' do
            let(:submodule) { '../six' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid submodule path' }
            end
          end
        end

        context 'commit_sha' do
          context 'is empty' do
            let(:commit_sha) { '' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'is not present' do
            let(:commit_sha) { nil }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'is invalid' do
            let(:commit_sha) { '1' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'is the same as the current ref' do
            let(:commit_sha) { current_sha }

            it_behaves_like 'returns error result' do
              let(:error_message) { "The submodule #{submodule} is already at #{commit_sha}" }
            end
          end
        end

        context 'branch_name' do
          context 'is empty' do
            let(:branch_name) { '' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'You can only create or edit files when you are on a branch' }
            end
          end

          context 'is not present' do
            let(:branch_name) { nil }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'Invalid parameters' }
            end
          end

          context 'does not exist' do
            let(:branch_name) { 'non/existent-branch' }

            it_behaves_like 'returns error result' do
              let(:error_message) { 'You can only create or edit files when you are on a branch' }
            end
          end

          context 'when commit message is empty' do
            let(:commit_message) { '' }

            it 'a default commit message is set' do
              message = "Update submodule #{submodule} with oid #{commit_sha}"

              expect(repository).to receive(:update_submodule).with(any_args, hash_including(message: message))

              subject.execute
            end
          end
        end
      end

      context 'when there is an unexpected error' do
        before do
          allow(repository).to receive(:update_submodule).and_raise(StandardError, 'error message')
        end

        it_behaves_like 'returns error result' do
          let(:error_message) { 'error message' }
        end
      end

      it 'updates the submodule reference' do
        result = subject.execute

        expect(result[:status]).to eq :success
        expect(result[:result]).to eq repository.head_commit.id
        expect(repository.blob_at('HEAD', submodule).id).to eq commit_sha
      end

      context 'when submodule is inside a directory' do
        let(:submodule) { 'test_inside_folder/another_folder/six' }
        let(:branch_name) { 'submodule_inside_folder' }

        it 'updates the submodule reference' do
          expect(repository.blob_at(branch_name, submodule).id).not_to eq commit_sha

          subject.execute

          expect(repository.blob_at(branch_name, submodule).id).to eq commit_sha
        end
      end

      context 'when repository is empty' do
        let(:project) { create(:project, :empty_repo) }
        let(:branch_name) { 'master' }

        it_behaves_like 'returns error result' do
          let(:error_message) { 'The repository is empty' }
        end
      end
    end
  end
end
