# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Checks::BranchCheck do
  include_context 'change access checks context'

  describe '#validate!' do
    it 'does not raise any error' do
      expect { subject.validate! }.not_to raise_error
    end

    context 'trying to delete the default branch' do
      let(:newrev) { '0000000000000000000000000000000000000000' }
      let(:ref) { 'refs/heads/master' }

      it 'raises an error' do
        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'The default branch of a project cannot be deleted.')
      end
    end

    context 'protected branches check' do
      before do
        allow(ProtectedBranch).to receive(:protected?).with(project, 'master').and_return(true)
        allow(ProtectedBranch).to receive(:protected?).with(project, 'feature').and_return(true)
      end

      it 'raises an error if the user is not allowed to do forced pushes to protected branches' do
        expect(Gitlab::Checks::ForcePush).to receive(:force_push?).and_return(true)

        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to force push code to a protected branch on this project.')
      end

      it 'raises an error if the user is not allowed to merge to protected branches' do
        expect_next_instance_of(Gitlab::Checks::MatchingMergeRequest) do |instance|
          expect(instance).to receive(:match?).and_return(true)
        end
        expect(user_access).to receive(:can_merge_to_branch?).and_return(false)
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to merge code into protected branches on this project.')
      end

      it 'raises an error if the user is not allowed to push to protected branches' do
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to push code to protected branches on this project.')
      end

      context 'when project repository is empty' do
        let(:project) { create(:project) }

        context 'user is not allowed to push to protected branches' do
          before do
            allow(user_access)
              .to receive(:can_push_to_branch?)
              .and_return(false)
          end

          it 'raises an error' do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /Ask a project Owner or Maintainer to create a default branch/)
          end
        end

        context 'user is allowed to push to protected branches' do
          before do
            allow(user_access)
              .to receive(:can_push_to_branch?)
              .and_return(true)
          end

          it 'allows branch creation' do
            expect { subject.validate! }.not_to raise_error
          end
        end
      end

      context 'branch creation' do
        let(:oldrev) { '0000000000000000000000000000000000000000' }
        let(:ref) { 'refs/heads/feature' }

        context 'user can push to branch' do
          before do
            allow(user_access)
              .to receive(:can_push_to_branch?)
              .with('feature')
              .and_return(true)
          end

          it 'does not raise an error' do
            expect { subject.validate! }.not_to raise_error
          end
        end

        context 'user cannot push to branch' do
          before do
            allow(user_access)
              .to receive(:can_push_to_branch?)
              .with('feature')
              .and_return(false)
          end

          context 'user cannot merge to branch' do
            before do
              allow(user_access)
                .to receive(:can_merge_to_branch?)
                .with('feature')
                .and_return(false)
            end

            it 'raises an error' do
              expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to create protected branches on this project.')
            end
          end

          context 'user can merge to branch' do
            before do
              allow(user_access)
                .to receive(:can_merge_to_branch?)
                .with('feature')
                .and_return(true)

              allow(project.repository)
                .to receive(:branch_names_contains_sha)
                .with(newrev)
                .and_return(['branch'])
            end

            context "newrev isn't in any protected branches" do
              before do
                allow(ProtectedBranch)
                  .to receive(:any_protected?)
                  .with(project, ['branch'])
                  .and_return(false)
              end

              it 'raises an error' do
                expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You can only use an existing protected branch ref as the basis of a new protected branch.')
              end
            end

            context 'newrev is included in a protected branch' do
              before do
                allow(ProtectedBranch)
                  .to receive(:any_protected?)
                  .with(project, ['branch'])
                  .and_return(true)
              end

              context 'via web interface' do
                let(:protocol) { 'web' }

                it 'allows branch creation' do
                  expect { subject.validate! }.not_to raise_error
                end
              end

              context 'via SSH' do
                it 'raises an error' do
                  expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You can only create protected branches using the web interface and API.')
                end
              end
            end
          end
        end
      end

      context 'branch deletion' do
        let(:newrev) { '0000000000000000000000000000000000000000' }
        let(:ref) { 'refs/heads/feature' }

        context 'if the user is not allowed to delete protected branches' do
          it 'raises an error' do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to delete protected branches from this project. Only a project maintainer or owner can delete a protected branch.')
          end
        end

        context 'if the user is allowed to delete protected branches' do
          before do
            project.add_maintainer(user)
          end

          context 'through the web interface' do
            let(:protocol) { 'web' }

            it 'allows branch deletion' do
              expect { subject.validate! }.not_to raise_error
            end
          end

          context 'over SSH or HTTP' do
            it 'raises an error' do
              expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You can only delete protected branches using the web interface.')
            end
          end
        end
      end
    end
  end
end
