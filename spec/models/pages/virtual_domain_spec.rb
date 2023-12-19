# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::VirtualDomain, feature_category: :pages do
  let(:domain) { nil }
  let(:trim_prefix) { nil }

  let_it_be(:group) { create(:group, path: 'mygroup') }
  let_it_be(:project_a) { create(:project, group: group) }
  let_it_be(:project_a_main_deployment) { create(:pages_deployment, project: project_a, path_prefix: nil) }
  let_it_be(:project_a_versioned_deployment) { create(:pages_deployment, project: project_a, path_prefix: 'v1') }
  let_it_be(:project_b) { create(:project, group: group) }
  let_it_be(:project_b_main_deployment) { create(:pages_deployment, project: project_b, path_prefix: nil) }
  let_it_be(:project_b_versioned_deployment) { create(:pages_deployment, project: project_b, path_prefix: 'v1') }
  let_it_be(:project_c) { create(:project, group: group) }
  let_it_be(:project_c_main_deployment) { create(:pages_deployment, project: project_c, path_prefix: nil) }
  let_it_be(:project_c_versioned_deployment) { create(:pages_deployment, project: project_c, path_prefix: 'v1') }

  before_all do
    # Those deployments are created to ensure that deactivated deployments won't be returned on the queries
    deleted_at = 1.hour.ago
    create(:pages_deployment, project: project_a, path_prefix: 'v2', deleted_at: deleted_at)
    create(:pages_deployment, project: project_b, path_prefix: 'v2', deleted_at: deleted_at)
    create(:pages_deployment, project: project_c, path_prefix: 'v2', deleted_at: deleted_at)
  end

  describe '#certificate and #key pair' do
    let(:project) { project_a }

    subject(:virtual_domain) { described_class.new(projects: [project], domain: domain) }

    it 'returns nil if there is no domain provided' do
      expect(virtual_domain.certificate).to be_nil
      expect(virtual_domain.key).to be_nil
    end

    context 'when Pages domain is provided' do
      let(:domain) { instance_double(PagesDomain, certificate: 'certificate', key: 'key') }

      it 'returns certificate and key from the provided domain' do
        expect(virtual_domain.certificate).to eq('certificate')
        expect(virtual_domain.key).to eq('key')
      end
    end
  end

  describe '#lookup_paths' do
    let(:project_list) { [project_a, project_b, project_c] }

    subject(:virtual_domain) do
      described_class.new(projects: project_list, domain: domain, trim_prefix: trim_prefix)
    end

    context 'when pages multiple versions is disabled' do
      before do
        allow(::Gitlab::Pages)
          .to receive(:multiple_versions_enabled_for?)
          .and_return(false)
      end

      it 'returns only the main deployments for each project' do
        global_ids = virtual_domain.lookup_paths.map do |lookup_path|
          lookup_path.source[:global_id]
        end

        expect(global_ids).to match_array([
          project_a_main_deployment.to_gid.to_s,
          project_b_main_deployment.to_gid.to_s,
          project_c_main_deployment.to_gid.to_s
        ])
      end
    end

    context 'when pages multiple versions is enabled' do
      before do
        allow(::Gitlab::Pages)
          .to receive(:multiple_versions_enabled_for?)
          .and_return(true)
      end

      it 'returns collection of projects pages lookup paths sorted by prefix in reverse' do
        global_ids = virtual_domain.lookup_paths.map do |lookup_path|
          lookup_path.source[:global_id]
        end

        expect(global_ids).to match_array([
          project_a_main_deployment.to_gid.to_s,
          project_a_versioned_deployment.to_gid.to_s,
          project_b_main_deployment.to_gid.to_s,
          project_b_versioned_deployment.to_gid.to_s,
          project_c_main_deployment.to_gid.to_s,
          project_c_versioned_deployment.to_gid.to_s
        ])
      end
    end
  end
end
