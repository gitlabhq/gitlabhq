require 'spec_helper'

describe Gitlab::UsageData do
  let!(:project) { create(:project) }
  let!(:project2) { create(:project) }
  let!(:board) { create(:board, project: project) }

  describe '#data' do
    subject { Gitlab::UsageData.data }

    it "gathers usage data" do
      expect(subject.keys).to match_array(%i(
        active_user_count
        counts
        historical_max_users
        license_add_ons
        license_expires_at
        license_starts_at
        license_user_count
        licensee
        license_md5
        recorded_at
        version
      ))
    end

    it "gathers usage counts" do
      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(2)

      expect(count_data.keys).to match_array(%i(
        boards
        ci_builds
        ci_pipelines
        ci_runners
        ci_triggers
        deploy_keys
        deployments
        environments
        geo_nodes
        groups
        issues
        keys
        labels
        ldap_group_links
        ldap_keys
        ldap_users
        lfs_objects
        merge_requests
        milestones
        notes
        projects
        pushes
        pages_domains
        protected_branchess
        releases
        remote_mirrors
        services
        snippets
        todos
        web_hooks
      ))
    end
  end

  describe '#license_usage_data' do
    subject { Gitlab::UsageData.license_usage_data }

    it "gathers license data" do
      license = ::License.current

      expect(subject[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
      expect(subject[:version]).to eq(Gitlab::VERSION)
      expect(subject[:licensee]).to eq(license.licensee)
      expect(subject[:active_user_count]).to eq(User.active.count)
      expect(subject[:licensee]).to eq(license.licensee)
      expect(subject[:license_user_count]).to eq(license.user_count)
      expect(subject[:license_starts_at]).to eq(license.starts_at)
      expect(subject[:license_expires_at]).to eq(license.expires_at)
      expect(subject[:license_add_ons]).to eq(license.add_ons)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end
end
