require 'spec_helper'

describe ProjectSnippetPolicy, models: true do
  let(:current_user) { create(:user) }

  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  subject { described_class.abilities(current_user, project_snippet).to_set }

  context 'public snippet' do
    let(:project_snippet) { create(:project_snippet, :public) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end
  end

  context 'internal snippet' do
    let(:project_snippet) { create(:project_snippet, :internal) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'external user' do
      let(:current_user) { create(:user, :external) }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end
  end

  context 'private snippet' do
    let(:project_snippet) { create(:project_snippet, :private) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'snippet author' do
      let(:project_snippet) { create(:project_snippet, :private, author: current_user) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.to include(*author_permissions)
      end
    end

    context 'project team member' do
      before { project_snippet.project.team << [current_user, :developer] }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'auditor user' do
      let(:current_user) { create(:user, :auditor) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'admin user' do
      let(:current_user) { create(:admin) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.to include(*author_permissions)
      end
    end
  end
end
