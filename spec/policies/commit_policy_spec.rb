# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitPolicy do
  describe '#rules' do
    let(:group) { create(:group, :public) }
    let(:user) { create(:user) }
    let(:commit) { project.repository.head_commit }
    let(:policy) { described_class.new(user, commit) }

    shared_examples 'can read commit and create a note' do
      it 'can read commit' do
        expect(policy).to be_allowed(:read_commit)
      end

      it 'can create a note' do
        expect(policy).to be_allowed(:create_note)
      end
    end

    shared_examples 'cannot read commit nor create a note' do
      it 'cannot read commit' do
        expect(policy).to be_disallowed(:read_commit)
      end

      it 'cannot create a note' do
        expect(policy).to be_disallowed(:create_note)
      end
    end

    context 'when project is public' do
      let(:project) { create(:project, :public, :repository, group: group) }

      context 'when the user is not a project member' do
        it_behaves_like 'can read commit and create a note'
      end

      context 'when repository access level is private' do
        let(:project) { create(:project, :public, :repository, :repository_private, group: group) }

        context 'when the user is not a project member' do
          it_behaves_like 'cannot read commit nor create a note'
        end

        context 'when the user is a direct project member' do
          context 'and the user is a developer' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'can read commit and create a note'
          end
        end

        context 'when the user is an inherited member from the group' do
          context 'and the user is a guest' do
            before do
              group.add_guest(user)
            end

            it_behaves_like 'can read commit and create a note'
          end

          context 'and the user is a reporter' do
            before do
              group.add_reporter(user)
            end

            it_behaves_like 'can read commit and create a note'
          end

          context 'and the user is a developer' do
            before do
              group.add_developer(user)
            end

            it_behaves_like 'can read commit and create a note'
          end
        end
      end
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, :repository, group: group) }

      context 'when the user is not a project member' do
        it_behaves_like 'cannot read commit nor create a note'
      end

      context 'when the user is a direct project member' do
        context 'and the user is a developer' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'can read commit and create a note'
        end

        context 'and the user is a guest' do
          before do
            project.add_guest(user)
          end

          it_behaves_like 'cannot read commit nor create a note'

          it 'cannot download code' do
            expect(policy).to be_disallowed(:download_code)
          end
        end
      end

      context 'when the user is an inherited member from the group' do
        context 'and the user is a guest' do
          before do
            group.add_guest(user)
          end

          it_behaves_like 'cannot read commit nor create a note'
        end

        context 'and the user is a reporter' do
          before do
            group.add_reporter(user)
          end

          it_behaves_like 'can read commit and create a note'
        end

        context 'and the user is a developer' do
          before do
            group.add_developer(user)
          end

          it_behaves_like 'can read commit and create a note'
        end
      end
    end
  end
end
