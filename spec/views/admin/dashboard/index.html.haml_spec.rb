# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/index.html.haml' do
  include Devise::Test::ControllerHelpers
  include StubVersion

  let(:kas_enabled) { false }

  let_it_be(:user) { create(:admin) }

  before do
    counts = Admin::DashboardController::COUNTED_ITEMS.index_with { 100 }

    assign(:counts, counts)
    assign(:projects, create_list(:project, 1))
    assign(:users, create_list(:user, 1))
    assign(:groups, create_list(:group, 1))

    allow(Gitlab::Kas).to receive(:enabled?).and_return(kas_enabled)
    allow(view).to receive(:admin?).and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "shows version of GitLab Workhorse" do
    render

    expect(rendered).to have_content 'GitLab Workhorse'
    expect(rendered).to have_content Gitlab::Workhorse.version
  end

  it "includes revision of GitLab for pre VERSION" do
    stub_version('13.11.0-pre', 'abcdefg')

    render

    expect(rendered).to have_content "13.11.0-pre abcdefg"
  end

  it 'shows the tag for GitLab version' do
    stub_version('13.11.0', 'abcdefg')

    render

    expect(rendered).to have_content "13.11.0"
    expect(rendered).not_to have_content "abcdefg"
  end

  it 'does not include license breakdown' do
    render

    expect(rendered).not_to have_content "Users in License"
    expect(rendered).not_to have_content "Billable Users"
    expect(rendered).not_to have_content "Maximum Users"
    expect(rendered).not_to have_content "Users over License"
  end

  it 'shows database versions for all database models' do
    render

    expect(rendered).to have_content(/PostgreSQL \(main\).+?#{::Gitlab::Database::Reflection.new(ApplicationRecord).version}/)

    if Gitlab::Database.has_config?(:ci)
      expect(rendered).to have_content(/PostgreSQL \(ci\).+?#{::Gitlab::Database::Reflection.new(Ci::ApplicationRecord).version}/)
    end
  end

  describe 'when show_version_check? is true' do
    before do
      allow(view).to receive(:show_version_check?).and_return(true)
      render
    end

    it 'renders the version check badge' do
      expect(rendered).to have_selector('.js-gitlab-version-check-badge')
    end
  end

  describe 'GitLab KAS', feature_category: :deployment_management do
    context 'when KAS is enabled' do
      let(:retrieved_server_info?) { true }

      before do
        server_info = instance_double(
          Gitlab::Kas::ServerInfo,
          retrieved_server_info?: retrieved_server_info?,
          version: '17.4.0-rc1'
        )
        presenter = Gitlab::Kas::ServerInfoPresenter.new(server_info)
        allow(presenter).to receive(:git_ref_for_display).and_return('6a0281c6896')
        allow(presenter).to receive(:git_ref_url).and_return('some/url')
        assign(:kas_server_info, presenter)
      end

      context 'when successfully fetched KAS version' do
        it 'includes KAS version' do
          render

          expect(rendered).to have_content("GitLab KAS 17.4.0-rc1 6a0281c6896")
          expect(rendered).to have_link('6a0281c6896', href: 'some/url')
        end
      end

      context 'when failed to fetch KAS version' do
        let(:retrieved_server_info?) { false }

        it 'includes error message' do
          render

          expect(rendered).to have_content("GitLab KAS Unknown")
        end
      end
    end

    context 'when KAS is disabled' do
      it 'does not include KAS version' do
        render

        expect(rendered).not_to have_content('GitLab KAS')
      end
    end
  end

  context 'with "jh transition banner" part' do
    let(:user) { build(:user, preferred_language: 'uk') }

    before do
      allow(view).to receive(:show_transition_to_jihu_callout?).and_return(true)
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'renders the banner class ".js-jh-transition-banner"' do
      render

      expect(rendered).to have_selector('.js-jh-transition-banner')
      expect(rendered).to have_selector("[data-feature-name='transition_to_jihu_callout']")
      expect(rendered).to have_selector("[data-user-preferred-language='uk']")
    end
  end
end
