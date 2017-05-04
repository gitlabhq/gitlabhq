require 'spec_helper'

describe PersonalSnippetPolicy, models: true do
  let(:regular_user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:admin_user) { create(:user, :admin) }

  let(:author_permissions) do
    [
      :update_personal_snippet,
      :admin_personal_snippet,
      :destroy_personal_snippet
    ]
  end

  def permissions(user)
    described_class.abilities(user, snippet).to_set
  end

  context 'public snippet' do
    let(:snippet) { create(:personal_snippet, :public) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.to include(:comment_personal_snippet)
        is_expected.to include(*author_permissions)
      end
    end
  end

  context 'internal snippet' do
    let(:snippet) { create(:personal_snippet, :internal) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.not_to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'external user' do
      subject { permissions(external_user) }

      it do
        is_expected.not_to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'snippet author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.to include(:comment_personal_snippet)
        is_expected.to include(*author_permissions)
      end
    end
  end

  context 'private snippet' do
    let(:snippet) { create(:project_snippet, :private) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.not_to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.not_to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'external user' do
      subject { permissions(external_user) }

      it do
        is_expected.not_to include(:read_personal_snippet)
        is_expected.not_to include(:comment_personal_snippet)
        is_expected.not_to include(*author_permissions)
      end
    end

    context 'snippet author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to include(:read_personal_snippet)
        is_expected.to include(:comment_personal_snippet)
        is_expected.to include(*author_permissions)
      end
    end
  end
end
