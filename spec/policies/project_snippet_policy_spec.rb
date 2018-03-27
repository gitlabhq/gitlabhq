require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/support/snippet_visibility.rb
describe ProjectSnippetPolicy do
  let(:regular_user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:project) { create(:project, :public) }

  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  def abilities(user, snippet_visibility)
    snippet = create(:project_snippet, snippet_visibility, project: project)

    described_class.new(user, snippet)
  end

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'public snippet' do
    context 'no user' do
      subject { abilities(nil, :public) }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :public) }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      subject { abilities(external_user, :public) }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end
  end

  context 'internal snippet' do
    context 'no user' do
      subject { abilities(nil, :internal) }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :internal) }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      subject { abilities(external_user, :internal) }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'project team member external user' do
      subject { abilities(external_user, :internal) }

      before do
        project.add_developer(external_user)
      end

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end
  end

  context 'private snippet' do
    context 'no user' do
      subject { abilities(nil, :private) }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :private) }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'snippet author' do
      let(:snippet) { create(:project_snippet, :private, author: regular_user, project: project) }

      subject { described_class.new(regular_user, snippet) }

      it do
        expect_allowed(:read_project_snippet)
        expect_allowed(*author_permissions)
      end
    end

    context 'project team member normal user' do
      subject { abilities(regular_user, :private) }

      before do
        project.add_developer(regular_user)
      end

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'project team member external user' do
      subject { abilities(external_user, :private) }

      before do
        project.add_developer(external_user)
      end

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'admin user' do
      subject { abilities(create(:admin), :private) }

      it do
        expect_allowed(:read_project_snippet)
        expect_allowed(*author_permissions)
      end
    end
  end
end
