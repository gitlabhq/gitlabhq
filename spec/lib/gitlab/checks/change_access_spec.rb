require 'spec_helper'

describe Gitlab::Checks::ChangeAccess, lib: true do
  describe '#exec' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:user_access) { Gitlab::UserAccess.new(user, project: project) }
    let(:changes) do
      {
        oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
        newrev: '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51',
        ref: 'refs/heads/master'
      }
    end

    subject { described_class.new(changes, project: project, user_access: user_access).exec }

    before { allow(user_access).to receive(:can_do_action?).with(:push_code).and_return(true) }

    context 'without failed checks' do
      it "doesn't return any error" do
        expect(subject.status).to be(true)
      end
    end

    context 'when the user is not allowed to push code' do
      it 'returns an error' do
        expect(user_access).to receive(:can_do_action?).with(:push_code).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to push code to this project.')
      end
    end

    context 'tags check' do
      let(:changes) do
        {
          oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
          newrev: '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51',
          ref: 'refs/tags/v1.0.0'
        }
      end

      it 'returns an error if the user is not allowed to update tags' do
        expect(user_access).to receive(:can_do_action?).with(:admin_project).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to change existing tags on this project.')
      end
    end

    context 'protected branches check' do
      before do
        allow(project).to receive(:protected_branch?).with('master').and_return(true)
      end

      it 'returns an error if the user is not allowed to do forced pushes to protected branches' do
        expect(Gitlab::Checks::ForcePush).to receive(:force_push?).and_return(true)
        expect(user_access).to receive(:can_do_action?).with(:force_push_code_to_protected_branches).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to force push code to a protected branch on this project.')
      end

      it 'returns an error if the user is not allowed to merge to protected branches' do
        expect_any_instance_of(Gitlab::Checks::MatchingMergeRequest).to receive(:match?).and_return(true)
        expect(user_access).to receive(:can_merge_to_branch?).and_return(false)
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to merge code into protected branches on this project.')
      end

      it 'returns an error if the user is not allowed to push to protected branches' do
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to push code to protected branches on this project.')
      end

      context 'branch deletion' do
        let(:changes) do
          {
            oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
            newrev: '0000000000000000000000000000000000000000',
            ref: 'refs/heads/master'
          }
        end

        it 'returns an error if the user is not allowed to delete protected branches' do
          expect(user_access).to receive(:can_do_action?).with(:remove_protected_branches).and_return(false)

          expect(subject.status).to be(false)
          expect(subject.message).to eq('You are not allowed to delete protected branches from this project.')
        end
      end
    end
  end
end
