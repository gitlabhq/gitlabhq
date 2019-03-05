# frozen_string_literal: true

require 'spec_helper'

describe CommitPolicy do
  describe '#rules' do
    let(:user) { create(:user) }
    let(:commit) { project.repository.head_commit }
    let(:policy) { described_class.new(user, commit) }

    context 'when project is public' do
      let(:project) { create(:project, :public, :repository) }

      it 'can read commit and create a note' do
        expect(policy).to be_allowed(:read_commit)
      end

      context 'when repository access level is private' do
        let(:project) { create(:project, :public, :repository, :repository_private) }

        it 'can not read commit and create a note' do
          expect(policy).to be_disallowed(:read_commit)
        end

        context 'when the user is a project member' do
          before do
            project.add_developer(user)
          end

          it 'can read commit and create a note' do
            expect(policy).to be_allowed(:read_commit)
          end
        end
      end
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, :repository) }

      it 'can not read commit and create a note' do
        expect(policy).to be_disallowed(:read_commit)
      end

      context 'when the user is a project member' do
        before do
          project.add_developer(user)
        end

        it 'can read commit and create a note' do
          expect(policy).to be_allowed(:read_commit)
        end
      end
    end
  end
end
