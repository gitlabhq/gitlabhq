require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/support/snippet_visibility.rb
describe ProjectSnippetPolicy do
  let(:regular_user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:project) { create(:project, :public) }
  let(:snippet) { create(:project_snippet, snippet_visibility, project: project) }
  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  subject { described_class.new(current_user, snippet) }

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
    end

    context 'external user' do
      let(:current_user) { external_user }

      it do
        expect_allowed(:read_project_snippet, :create_note)
        expect_disallowed(*author_permissions)
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

      context 'snippet author' do
        let(:snippet) { create(:project_snippet, :private, author: regular_user, project: project) }

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_allowed(*author_permissions)
        end
      end

      context 'project team member normal user' do
        before do
          project.add_developer(regular_user)
        end

        it do
          expect_allowed(:read_project_snippet, :create_note)
          expect_disallowed(*author_permissions)
        end
      end
    end

    context 'external user' do
      context 'project team member' do
        let(:current_user) { external_user }

        before do
          project.add_developer(external_user)
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
