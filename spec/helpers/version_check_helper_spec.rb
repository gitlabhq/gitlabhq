# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VersionCheckHelper do
  include StubVersion

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
          allow(user).to receive(:can_admin_all_resources?).and_return(is_admin)
        end

        it 'returns correct results' do
          expect(helper.show_version_check?).to eq result
        end
      end
    end
  end

  describe '#gitlab_version_check' do
    let(:show_version_check) { false }

    before do
      allow(helper).to receive(:show_version_check?).and_return(show_version_check)
    end

    it 'when show_version_check? is false it returns nil' do
      expect(helper.gitlab_version_check).to be nil
    end

    context 'when show_version_check? is true' do
      let(:show_version_check) { true }

      before do
        allow_next_instance_of(VersionCheck) do |instance|
          allow(instance).to receive(:response).and_return({ "severity" => "success" })
        end
      end

      it 'returns an instance of the VersionCheck class if the user has access' do
        expect(helper.gitlab_version_check).to eq({ "severity" => "success" })
      end
    end
  end

  describe '#show_security_patch_upgrade_alert?' do
    describe 'return conditions' do
      where(:gitlab_version_check, :result) do
        [
          [nil, false],
          [{}, nil],
          [{ "severity" => "success" }, nil],
          [{ "severity" => "danger" }, nil],
          [{ "severity" => "danger", "critical_vulnerability" => 'some text' }, nil],
          [{ "severity" => "danger", "critical_vulnerability" => 'false' }, false],
          [{ "severity" => "danger", "critical_vulnerability" => false }, false],
          [{ "severity" => "danger", "critical_vulnerability" => 'true' }, true],
          [{ "severity" => "danger", "critical_vulnerability" => true }, true]
        ]
      end

      with_them do
        before do
          allow(helper).to receive(:gitlab_version_check).and_return(gitlab_version_check)
        end

        it 'returns correct results' do
          expect(helper.show_security_patch_upgrade_alert?).to eq result
        end
      end
    end
  end

  describe '#link_to_version' do
    let(:release_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/-/tags/deadbeef' }

    before do
      allow(Gitlab::Source).to receive(:release_url).and_return(release_url)
    end

    context 'for a pre-release' do
      before do
        stub_version('8.0.2-pre', 'deadbeef')
      end

      it 'links to commit sha' do
        expect(helper.link_to_version).to eq("8.0.2-pre <small><a href=\"#{release_url}\">deadbeef</a></small>")
      end
    end

    context 'for a normal release' do
      before do
        stub_version('8.0.2-ee', 'deadbeef')
      end

      it 'links to version tag' do
        expect(helper.link_to_version).to include("<a href=\"#{release_url}\">v8.0.2-ee</a>")
      end
    end
  end
end
