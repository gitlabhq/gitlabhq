# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GonHelper, feature_category: :shared do
  let_it_be(:organization) { create(:organization) }
  let(:helper) do
    Class.new do
      include Gitlab::GonHelper
    end.new
  end

  describe '#add_gon_variables' do
    let(:gon) { double('gon').as_null_object }
    let(:https) { true }

    before do
      allow(helper).to receive(:current_user).and_return(nil)
      allow(helper).to receive(:gon).and_return(gon)
      stub_config_setting(https: https)
    end

    context 'when HTTPS is enabled' do
      it 'sets the secure flag to true' do
        expect(gon).to receive(:secure=).with(true)

        helper.add_gon_variables
      end
    end

    context 'when HTTP is enabled' do
      let(:https) { false }

      it 'sets the secure flag to false' do
        expect(gon).to receive(:secure=).with(false)

        helper.add_gon_variables
      end
    end

    it 'sets no GitLab version' do
      expect(gon).not_to receive(:version=)

      helper.add_gon_variables
    end

    context 'when user is logged in' do
      before do
        allow(helper).to receive(:current_user).and_return(build_stubbed(:user))
      end

      it 'sets GitLab version' do
        expect(gon).to receive(:version=).with(Gitlab::VERSION)

        helper.add_gon_variables
      end
    end

    context 'when sentry is configured' do
      let(:clientside_dsn) { 'https://xxx@sentry.example.com/1' }
      let(:environment) { 'staging' }
      let(:sentry_clientside_traces_sample_rate) { 0.5 }

      context 'with sentry settings' do
        before do
          stub_application_setting(sentry_enabled: true)
          stub_application_setting(sentry_clientside_dsn: clientside_dsn)
          stub_application_setting(sentry_environment: environment)
          stub_application_setting(sentry_clientside_traces_sample_rate: sentry_clientside_traces_sample_rate)
        end

        it 'sets sentry dsn and environment from config' do
          expect(gon).to receive(:sentry_dsn=).with(clientside_dsn)
          expect(gon).to receive(:sentry_environment=).with(environment)
          expect(gon).to receive(:sentry_clientside_traces_sample_rate=).with(sentry_clientside_traces_sample_rate)

          helper.add_gon_variables
        end
      end
    end

    context 'when ui_for_organizations feature flag is enabled' do
      context 'when current_organization is set', :with_current_organization do
        subject(:add_gon_variables) { helper.add_gon_variables }

        before do
          Current.organization = current_organization
        end

        it 'exposes current_organization' do
          expect(gon).to receive(:current_organization=).with(
            current_organization.slice(:id, :name, :web_url, :avatar_url)
          )

          add_gon_variables
        end

        it_behaves_like 'internal event not tracked'
      end

      context 'when current_organization is not set' do
        it 'does not expose current_organization' do
          expect(gon).not_to receive(:current_organization=)

          helper.add_gon_variables
        end
      end
    end

    context 'when ui_for_organizations feature flag is disabled', :with_current_organization do
      before do
        stub_feature_flags(ui_for_organizations: false)
      end

      it 'does not expose current_organization' do
        expect(gon).not_to receive(:current_organization=)

        helper.add_gon_variables
      end
    end
  end

  describe '#push_frontend_ability' do
    it 'pushes an ability to the frontend' do
      user = create(:user)
      gon = class_double('Gon')
      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(gon)
        .to receive(:push)
        .with({ abilities: { 'logIn' => true } }, true)

      helper.push_frontend_ability(ability: :log_in, user: user)
    end
  end

  describe '#push_frontend_feature_flag' do
    before do
      skip_default_enabled_yaml_check
    end

    it 'pushes a feature flag to the frontend' do
      gon = class_double('Gon')
      thing = stub_feature_flag_gate('thing')

      stub_feature_flags(my_feature_flag: thing)
      stub_feature_flag_definition(:my_feature_flag)

      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(gon)
        .to receive(:push)
        .with({ features: { 'myFeatureFlag' => true } }, true)

      helper.push_frontend_feature_flag(:my_feature_flag, thing)
    end
  end

  describe '#push_force_frontend_feature_flag' do
    let(:gon) { class_double('Gon') }

    before do
      allow(helper)
        .to receive(:gon)
        .and_return(gon)
    end

    it 'pushes a feature flag to the frontend with the provided value' do
      expect(gon)
        .to receive(:push)
        .with({ features: { 'myFeatureFlag' => true } }, true)

      helper.push_force_frontend_feature_flag(:my_feature_flag, true)
    end

    it 'pushes a disabled feature flag if provided value is nil' do
      expect(gon)
        .to receive(:push)
        .with({ features: { 'myFeatureFlag' => false } }, true)

      helper.push_force_frontend_feature_flag(:my_feature_flag, nil)
    end
  end

  describe '#push_namespace_setting' do
    it 'pushes a namespace setting to the frontend' do
      namespace_settings = create(:namespace_settings, math_rendering_limits_enabled: false)
      group = create(:group, namespace_settings: namespace_settings)

      gon = class_double('Gon')
      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(gon)
        .to receive(:push)
        .with({ math_rendering_limits_enabled: false })

      helper.push_namespace_setting(:math_rendering_limits_enabled, group)
    end

    it 'does not push if missing namespace setting entry' do
      group = create(:group)

      gon = class_double('Gon')
      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(gon)
        .not_to receive(:push)
        .with({ math_rendering_limits_enabled: false })

      helper.push_namespace_setting(:math_rendering_limits_enabled, group)
    end
  end

  describe '#default_avatar_url' do
    it 'returns an absolute URL' do
      url = helper.default_avatar_url

      expect(url).to match(/^http/)
      expect(url).to match(/no_avatar.*png$/)
    end
  end

  describe '#add_browsersdk_tracking' do
    let(:gon) { double('gon').as_null_object }
    let(:analytics_url) { 'https://analytics.gitlab.com' }
    let(:is_gitlab_com) { true }

    before do
      allow(helper).to receive(:gon).and_return(gon)
      allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
    end

    context 'when environment variables are set' do
      before do
        stub_env('GITLAB_ANALYTICS_URL', analytics_url)
        stub_env('GITLAB_ANALYTICS_ID', 'analytics-id')
      end

      it 'sets the analytics_url and analytics_id' do
        expect(gon).to receive(:analytics_url=).with(analytics_url)
        expect(gon).to receive(:analytics_id=).with('analytics-id')

        helper.add_browsersdk_tracking
      end

      context 'when Gitlab.com? is false' do
        let(:is_gitlab_com) { false }

        it "doesn't set the analytics_url and analytics_id" do
          expect(gon).not_to receive(:analytics_url=)
          expect(gon).not_to receive(:analytics_id=)

          helper.add_browsersdk_tracking
        end
      end
    end

    context 'when environment variables are not set' do
      before do
        stub_env('GITLAB_ANALYTICS_URL', nil)
        stub_env('GITLAB_ANALYTICS_ID', nil)
      end

      it "doesn't set the analytics_url and analytics_id" do
        expect(gon).not_to receive(:analytics_url=)
        expect(gon).not_to receive(:analytics_id=)

        helper.add_browsersdk_tracking
      end
    end
  end
end
