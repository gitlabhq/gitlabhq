# frozen_string_literal: true

require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/finders/snippets_finder_spec.rb
RSpec.describe ProjectSnippetPolicy do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:regular_user) { create(:user) }
  let_it_be(:external_user) { create(:user, :external) }
  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:author) { create(:user) }
  let_it_be(:author_permissions) do
    [
      :update_snippet,
      :admin_snippet
    ]
  end

  let(:snippet) { build(:project_snippet, snippet_visibility, project: project, author: author) }

  subject { described_class.new(current_user, snippet) }

  shared_examples 'regular user member permissions' do
    context 'not snippet author' do
      context 'member (guest)' do
        before do
          membership_target.add_guest(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end

      context 'member (reporter)' do
        before do
          membership_target.add_reporter(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end

      context 'member (developer)' do
        before do
          membership_target.add_developer(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end

      context 'member (maintainer)' do
        before do
          membership_target.add_maintainer(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note, *author_permissions)
        end
      end
    end

    context 'snippet author' do
      let(:author) { current_user }

      context 'member (guest)' do
        before do
          membership_target.add_guest(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note, :update_snippet)
          expect_disallowed(:admin_snippet)
        end
      end

      context 'member (reporter)' do
        before do
          membership_target.add_reporter(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note, *author_permissions)
        end
      end

      context 'member (developer)' do
        before do
          membership_target.add_developer(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note, *author_permissions)
        end
      end

      context 'member (maintainer)' do
        before do
          membership_target.add_maintainer(current_user)
        end

        it do
          expect_allowed(:read_snippet, :create_note, *author_permissions)
        end
      end
    end
  end

  shared_examples 'regular user non-member author permissions' do
    let(:author) { current_user }

    it do
      expect_allowed(:read_snippet, :create_note, :update_snippet)
      expect_disallowed(:admin_snippet)
    end
  end

  context 'when project is public' do
    let_it_be(:project) { create(:project, :public, group: group) }

    context 'with public snippet' do
      let(:snippet_visibility) { :public }

      context 'no user' do
        let(:current_user) { nil }

        it do
          expect_allowed(:read_snippet)
          expect_disallowed(*author_permissions)
          expect_allowed(:cache_blob)
        end
      end

      context 'regular user' do
        let(:current_user) { regular_user }
        let(:membership_target) { project }

        context 'when user is not a member' do
          context 'and is not the snippet author' do
            it do
              expect_allowed(:read_snippet, :create_note)
              expect_disallowed(*author_permissions)
            end
          end

          context 'and is the snippet author' do
            it_behaves_like 'regular user non-member author permissions'
          end
        end

        context 'when user is a member' do
          it_behaves_like 'regular user member permissions'
        end
      end

      context 'external user' do
        let(:current_user) { external_user }

        it do
          expect_allowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end

        context 'when user is a member' do
          before do
            project.add_developer(external_user)
          end

          it do
            expect_allowed(:read_snippet, :create_note)
            expect_disallowed(*author_permissions)
          end
        end
      end
    end

    context 'with internal snippet' do
      let(:snippet_visibility) { :internal }

      context 'no user' do
        let(:current_user) { nil }

        it do
          expect_disallowed(:read_snippet)
          expect_disallowed(*author_permissions)
        end
      end

      context 'regular user' do
        let(:current_user) { regular_user }
        let(:membership_target) { project }

        context 'when user is not a member' do
          context 'and is not the snippet author' do
            it do
              expect_allowed(:read_snippet, :create_note)
              expect_disallowed(*author_permissions)
            end
          end

          context 'and is the snippet author' do
            it_behaves_like 'regular user non-member author permissions'
          end
        end

        context 'when user is a member' do
          it_behaves_like 'regular user member permissions'
        end
      end

      context 'external user' do
        let(:current_user) { external_user }

        it do
          expect_disallowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end

        context 'when user is a member' do
          before do
            project.add_developer(external_user)
          end

          it do
            expect_allowed(:read_snippet, :create_note)
            expect_disallowed(*author_permissions)
          end
        end
      end
    end

    context 'with private snippet' do
      let(:snippet_visibility) { :private }

      context 'no user' do
        let(:current_user) { nil }

        it do
          expect_disallowed(:read_snippet)
          expect_disallowed(*author_permissions)
          expect_disallowed(:cache_blob)
        end
      end

      context 'regular user' do
        let(:current_user) { regular_user }
        let(:membership_target) { project }

        context 'when user is not a member' do
          context 'and is not the snippet author' do
            it do
              expect_disallowed(:read_snippet, :create_note)
              expect_disallowed(*author_permissions)
            end
          end

          context 'and is the snippet author' do
            it_behaves_like 'regular user non-member author permissions'
          end
        end

        context 'when user is a member' do
          it_behaves_like 'regular user member permissions'
        end
      end

      context 'inherited user' do
        let(:current_user) { regular_user }
        let(:membership_target) { group }

        it_behaves_like 'regular user member permissions'
      end

      context 'external user' do
        let(:current_user) { external_user }

        it do
          expect_disallowed(:read_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end

        context 'when user is a member' do
          before do
            project.add_developer(current_user)
          end

          it do
            expect_allowed(:read_snippet, :create_note)
            expect_disallowed(*author_permissions)
          end
        end
      end

      context 'admin user' do
        let(:snippet_visibility) { :private }
        let(:current_user) { admin_user }

        context 'when admin mode is enabled', :enable_admin_mode do
          it do
            expect_allowed(:read_snippet, :create_note)
            expect_allowed(*author_permissions)
          end
        end

        context 'when admin mode is disabled' do
          it do
            expect_disallowed(:read_snippet, :create_note)
            expect_disallowed(*author_permissions)
          end
        end
      end
    end
  end

  context 'when project is private' do
    let_it_be(:project) { create(:project, :private, group: group) }

    let(:snippet_visibility) { :private }

    context 'inherited user' do
      let(:current_user) { regular_user }
      let(:membership_target) { group }

      it_behaves_like 'regular user member permissions'
    end

    context 'no user' do
      let(:current_user) { nil }

      context 'with public snippet' do
        let(:snippet_visibility) { :public }

        it do
          expect_disallowed(:cache_blob)
        end
      end

      context 'with private snippet' do
        let(:snippet_visibility) { :private }

        it do
          expect_disallowed(:cache_blob)
        end
      end
    end
  end

  context 'when the author of the snippet is banned', feature_category: :insider_threat do
    let(:banned_user) { build(:user, :banned) }
    let(:project) { build(:project, :public, group: group) }
    let(:snippet) { build(:project_snippet, :public, project: project, author: banned_user) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_snippet)
        expect_disallowed(:read_note)
        expect_disallowed(:create_note)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      let(:current_user) { regular_user }
      let(:membership_target) { project }

      it do
        expect_disallowed(:read_snippet)
        expect_disallowed(:read_note)
        expect_disallowed(:create_note)
        expect_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      let(:current_user) { external_user }
      let(:membership_target) { project }

      it do
        expect_disallowed(:read_snippet)
        expect_disallowed(:read_note)
        expect_disallowed(:create_note)
        expect_disallowed(*author_permissions)
      end
    end

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin_user }
      let(:membership_target) { project }

      it do
        expect_allowed(:read_snippet)
        expect_allowed(:read_note)
        expect_allowed(:create_note)
        expect_allowed(*author_permissions)
      end
    end
  end
end
