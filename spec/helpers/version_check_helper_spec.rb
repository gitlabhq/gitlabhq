# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VersionCheckHelper do
  let_it_be(:user) { create(:user) }

  describe '#show_version_check?' do
    describe 'return conditions' do
      where(:enabled, :consent, :is_admin, :result) do
        [
          [false, false, false, false],
          [false, false, true, false],
          [false, true, false, false],
          [false, true, true, false],
          [true, false, false, false],
          [true, false, true, true],
          [true, true, false, false],
          [true, true, true, false]
        ]
      end

      with_them do
        before do
          stub_application_setting(version_check_enabled: enabled)
          allow(User).to receive(:single_user).and_return(double(user, requires_usage_stats_consent?: consent))
          allow(helper).to receive(:current_user).and_return(user)
          allow(user).to receive(:can_read_all_resources?).and_return(is_admin)
        end

        it 'returns correct results' do
          expect(helper.show_version_check?).to eq result
        end
      end
    end
  end

  describe '#gitlab_version_check' do
    before do
      allow_next_instance_of(VersionCheck) do |instance|
        allow(instance).to receive(:response).and_return({ "severity" => "success" })
      end
    end

    it 'returns an instance of the VersionCheck class' do
      expect(helper.gitlab_version_check).to eq({ "severity" => "success" })
    end
  end

  describe '#show_security_patch_upgrade_alert?' do
    describe 'return conditions' do
      where(:feature_enabled, :show_version_check, :gitlab_version_check, :result) do
        [
          [false, false, nil, false],
          [false, false, { "severity" => "success" }, false],
          [false, false, { "severity" => "danger" }, false],
          [false, true, nil, false],
          [false, true, { "severity" => "success" }, false],
          [false, true, { "severity" => "danger" }, false],
          [true, false, nil, false],
          [true, false, { "severity" => "success" }, false],
          [true, false, { "severity" => "danger" }, false],
          [true, true, nil, false],
          [true, true, { "severity" => "success" }, false],
          [true, true, { "severity" => "danger" }, true]
        ]
      end

      with_them do
        before do
          stub_feature_flags(critical_security_alert: feature_enabled)
          allow(helper).to receive(:show_version_check?).and_return(show_version_check)
          allow(helper).to receive(:gitlab_version_check).and_return(gitlab_version_check)
        end

        it 'returns correct results' do
          expect(helper.show_security_patch_upgrade_alert?).to eq result
        end
      end
    end
  end
end
