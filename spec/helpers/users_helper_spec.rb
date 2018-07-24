require 'rails_helper'

describe UsersHelper do
  include TermsHelper

  let(:user) { create(:user) }

  describe '#user_link' do
    subject { helper.user_link(user) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's email as title" do
      is_expected.to include("title=\"#{user.email}\"")
    end
  end

  describe '#profile_tabs' do
    subject(:tabs) { helper.profile_tabs }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    context 'with public profile' do
      it 'includes all the expected tabs' do
        expect(tabs).to include(:activity, :groups, :contributed, :projects, :snippets)
      end
    end

    context 'with private profile' do
      before do
        allow(helper).to receive(:can?).with(user, :read_user_profile, nil).and_return(false)
      end

      it 'is empty' do
        expect(tabs).to be_empty
      end
    end
  end

  describe '#current_user_menu_items' do
    subject(:items) { helper.current_user_menu_items }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
    end

    it 'includes all default items' do
      expect(items).to include(:help, :sign_out)
    end

    it 'includes the profile tab if the user can read themself' do
      expect(helper).to receive(:can?).with(user, :read_user, user) { true }

      expect(items).to include(:profile)
    end

    it 'includes the settings tab if the user can update themself' do
      expect(helper).to receive(:can?).with(user, :read_user, user) { true }

      expect(items).to include(:profile)
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'hides the profile and the settings tab' do
        expect(items).not_to include(:settings, :profile, :help)
      end
    end
  end
end
