# frozen_string_literal: true

require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/support/snippet_visibility.rb
RSpec.describe PersonalSnippetPolicy do
  let(:regular_user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:admin_user) { create(:user, :admin) }

  let(:author_permissions) do
    [
      :update_snippet,
      :admin_snippet
    ]
  end

  def permissions(user)
    described_class.new(user, snippet)
  end

  shared_examples 'admin access with admin mode' do
    context 'admin user', :enable_admin_mode do
      subject { permissions(admin_user) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_allowed(*author_permissions)
      end
    end
  end

  context 'public snippet' do
    let(:snippet) { create(:personal_snippet, :public) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:cache_blob)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_allowed(*author_permissions)
      end
    end

    it_behaves_like 'admin access with admin mode'
  end

  context 'internal snippet' do
    let(:snippet) { create(:personal_snippet, :internal) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      subject { permissions(external_user) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'snippet author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_allowed(*author_permissions)
      end
    end

    it_behaves_like 'admin access with admin mode'
  end

  context 'private snippet' do
    let(:snippet) { create(:project_snippet, :private) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(:cache_blob)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      subject { permissions(external_user) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'snippet author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to be_allowed(:read_snippet)
        is_expected.to be_allowed(:create_note)
        is_expected.to be_allowed(:award_emoji)
        is_expected.to be_allowed(*author_permissions)
      end
    end

    it_behaves_like 'admin access with admin mode'
  end

  context 'when the author of the snippet is banned', feature_category: :insider_threat do
    let(:banned_user) { build(:user, :banned) }
    let(:snippet) { build(:personal_snippet, :public, author: banned_user) }

    context 'no user' do
      subject { permissions(nil) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(:award_emoji)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      subject { permissions(regular_user) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:read_note)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'external user' do
      subject { permissions(external_user) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:read_note)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    context 'snippet author' do
      subject { permissions(snippet.author) }

      it do
        is_expected.to be_disallowed(:read_snippet)
        is_expected.to be_disallowed(:read_note)
        is_expected.to be_disallowed(:create_note)
        is_expected.to be_disallowed(*author_permissions)
      end
    end

    it_behaves_like 'admin access with admin mode'
  end
end
