# frozen_string_literal: true

require 'spec_helper'

describe UsersHelper do
  include TermsHelper

  let(:user) { create(:user) }

  def filter_ee_badges(badges)
    badges.reject { |badge| badge[:text] == 'Is using seat' }
  end

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
        expect(tabs).to include(:activity, :groups, :contributed, :projects, :starred, :snippets)
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

  describe '#user_internal_regex_data' do
    using RSpec::Parameterized::TableSyntax

    where(:user_default_external, :user_default_internal_regex, :result) do
      false | nil                | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      false | ''                 | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      false | 'mockRegexPattern' | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | nil                | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | ''                 | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | 'mockRegexPattern' | { user_internal_regex_pattern: 'mockRegexPattern', user_internal_regex_options: 'i' }
    end

    with_them do
      before do
        stub_application_setting(user_default_external: user_default_external)
        stub_application_setting(user_default_internal_regex: user_default_internal_regex)
      end

      subject { helper.user_internal_regex_data }

      it { is_expected.to eq(result) }
    end
  end

  describe '#current_user_menu_items' do
    subject(:items) { helper.current_user_menu_items }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
    end

    after do
      expect(items).not_to include(:start_trial)
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

  describe '#user_badges_in_admin_section' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'with a blocked user' do
      it "returns the blocked badge" do
        blocked_user = create(:user, state: 'blocked')

        badges = helper.user_badges_in_admin_section(blocked_user)

        expect(filter_ee_badges(badges)).to eq([text: "Blocked", variant: "danger"])
      end
    end

    context 'with an admin user' do
      it "returns the admin badge" do
        admin_user = create(:admin)

        badges = helper.user_badges_in_admin_section(admin_user)

        expect(filter_ee_badges(badges)).to eq([text: "Admin", variant: "success"])
      end
    end

    context 'with an external user' do
      it 'returns the external badge' do
        external_user = create(:user, external: true)

        badges = helper.user_badges_in_admin_section(external_user)

        expect(filter_ee_badges(badges)).to eq([text: "External", variant: "secondary"])
      end
    end

    context 'with the current user' do
      it 'returns the "It\'s You" badge' do
        badges = helper.user_badges_in_admin_section(user)

        expect(filter_ee_badges(badges)).to eq([text: "It's you!", variant: nil])
      end
    end

    context 'with an external blocked admin' do
      it 'returns the blocked, admin and external badges' do
        user = create(:admin, state: 'blocked', external: true)

        badges = helper.user_badges_in_admin_section(user)

        expect(badges).to eq([
          { text: "Blocked", variant: "danger" },
          { text: "Admin", variant: "success" },
          { text: "External", variant: "secondary" }
        ])
      end
    end

    context 'get badges for normal user' do
      it 'returns no badges' do
        user = create(:user)

        badges = helper.user_badges_in_admin_section(user)

        expect(filter_ee_badges(badges)).to be_empty
      end
    end
  end
end
