require 'spec_helper'

describe ProjectSnippetPolicy, models: true do
  let(:regular_user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:project) { create(:empty_project, :public) }

  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  def abilities(user, snippet_visibility)
    snippet = create(:project_snippet, snippet_visibility, project: project)

    described_class.abilities(user, snippet).to_set
  end

  context 'public snippet' do
    context 'no user' do
      subject { abilities(nil, :public) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :public) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'external user' do
      subject { abilities(external_user, :public) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end
  end

  context 'internal snippet' do
    context 'no user' do
      subject { abilities(nil, :internal) }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :internal) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'external user' do
      subject { abilities(external_user, :internal) }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'project team member external user' do
      subject { abilities(external_user, :internal) }

      before { project.team << [external_user, :developer] }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end
  end

  context 'private snippet' do
    context 'no user' do
      subject { abilities(nil, :private) }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { abilities(regular_user, :private) }

      it do
        is_expected.not_to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'snippet author' do
      let(:snippet) { create(:project_snippet, :private, author: regular_user, project: project) }

      subject { described_class.abilities(regular_user, snippet).to_set }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.to include(*author_permissions)
      end
    end

    context 'project team member normal user' do
      subject { abilities(regular_user, :private) }

      before { project.team << [regular_user, :developer] }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'project team member external user' do
      subject { abilities(external_user, :private) }

      before { project.team << [external_user, :developer] }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'admin user' do
      subject { abilities(create(:admin), :private) }

      it do
        is_expected.to include(:read_project_snippet)
        is_expected.to include(*author_permissions)
      end
    end
  end
end
