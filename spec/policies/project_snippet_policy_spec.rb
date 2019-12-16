# frozen_string_literal: true

require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/support/snippet_visibility.rb
describe ProjectSnippetPolicy do
  let_it_be(:regular_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:external_user) { create(:user, :external) }
  let_it_be(:project) { create(:project, :public) }
  let(:snippet) { create(:project_snippet, snippet_visibility, project: project, author: author) }
  let(:author) { other_user }
  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  subject { described_class.new(current_user, snippet) }

  shared_examples 'regular user access rights' do
    context 'project team member (non guest)' do
      before do
        project.add_developer(current_user)
      end

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end
    end

    context 'project team member (guest)' do
      before do
        project.add_guest(current_user)
      end

      context 'not snippet author' do
        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(:admin_project_snippet)
        end
      end
    end

    context 'snippet author' do
      let(:author) { current_user }

      context 'project member (non guest)' do
        before do
          project.add_developer(current_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_allowed(*author_permissions)
        end
      end

      context 'project member (guest)' do
        before do
          project.add_guest(current_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(:admin_project_snippet)
        end
      end

      context 'not a project member' do
        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(:admin_project_snippet)
        end
      end
    end
  end

  context 'public snippet' do
    let(:snippet_visibility) { :public }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      let(:current_user) { regular_user }

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      it_behaves_like 'regular user access rights'
    end

    context 'external user' do
      let(:current_user) { external_user }

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      context 'project team member' do
        before do
          project.add_developer(external_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end
    end
  end

  context 'internal snippet' do
    let(:snippet_visibility) { :internal }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      let(:current_user) { regular_user }

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      it_behaves_like 'regular user access rights'
    end

    context 'external user' do
      let(:current_user) { external_user }

      it do
        expect_disallowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      context 'project team member' do
        before do
          project.add_developer(external_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end
    end
  end

  context 'private snippet' do
    let(:snippet_visibility) { :private }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      let(:current_user) { regular_user }

      it do
        expect_disallowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      it_behaves_like 'regular user access rights'
    end

    context 'external user' do
      let(:current_user) { external_user }

      it do
        expect_disallowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
      end

      context 'project team member' do
        before do
          project.add_developer(current_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end
    end

    context 'admin user' do
      let(:snippet_visibility) { :private }
      let(:current_user) { create(:admin) }

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_allowed(*author_permissions)
      end
    end
  end
end
