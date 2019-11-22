# frozen_string_literal: true

require 'spec_helper'

describe Clusters::ClusterPresenter do
  include Gitlab::Routing.url_helpers

  let(:cluster) { create(:cluster, :provided_by_gcp, :project) }
  let(:user) { create(:user) }

  subject(:presenter) do
    described_class.new(cluster, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a cluster and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes cluster' do
      expect(presenter.cluster).to eq(cluster)
    end

    it 'forwards missing methods to cluster' do
      expect(presenter.status).to eq(cluster.status)
    end
  end

  describe '#item_link' do
    let(:clusterable_presenter) { double('ClusterablePresenter', subject: clusterable) }

    subject { presenter.item_link(clusterable_presenter) }

    context 'for a group cluster' do
      let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [group]) }
      let(:group) { create(:group, name: 'Foo') }
      let(:cluster_link) { "<a href=\"#{group_cluster_path(cluster.group, cluster)}\">#{cluster.name}</a>" }

      before do
        group.add_maintainer(user)
      end

      shared_examples 'ancestor clusters' do
        context 'ancestor clusters' do
          let(:root_group) { create(:group, name: 'Root Group') }
          let(:parent) { create(:group, name: 'parent', parent: root_group) }
          let(:child) { create(:group, name: 'child', parent: parent) }
          let(:group) { create(:group, name: 'group', parent: child) }

          before do
            root_group.add_maintainer(user)
          end

          context 'top level group cluster' do
            let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [root_group]) }

            it 'returns full group names and link for cluster' do
              expect(subject).to eq("Root Group / #{cluster_link}")
            end

            it 'is html safe' do
              expect(presenter).to receive(:sanitize).with('Root Group').and_call_original

              expect(subject).to be_html_safe
            end
          end

          context 'first level group cluster' do
            let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [parent]) }

            it 'returns full group names and link for cluster' do
              expect(subject).to eq("Root Group / parent / #{cluster_link}")
            end

            it 'is html safe' do
              expect(presenter).to receive(:sanitize).with('Root Group / parent').and_call_original

              expect(subject).to be_html_safe
            end
          end

          context 'second level group cluster' do
            let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [child]) }

            let(:ellipsis_h) do
              /.*ellipsis_h.*/
            end

            it 'returns clipped group names and link for cluster' do
              expect(subject).to match("Root Group / #{ellipsis_h} / child / #{cluster_link}")
            end

            it 'is html safe' do
              expect(presenter).to receive(:sanitize).with('Root Group / parent / child').and_call_original

              expect(subject).to be_html_safe
            end
          end
        end
      end

      context 'for a project clusterable' do
        let(:clusterable) { project }
        let(:project) { create(:project, group: group) }

        it 'returns the group name and the link for cluster' do
          expect(subject).to eq("Foo / #{cluster_link}")
        end

        it 'is html safe' do
          expect(presenter).to receive(:sanitize).with('Foo').and_call_original

          expect(subject).to be_html_safe
        end

        include_examples 'ancestor clusters'
      end

      context 'for the group clusterable for the cluster' do
        let(:clusterable) { group }

        it 'returns link for cluster' do
          expect(subject).to eq(cluster_link)
        end

        include_examples 'ancestor clusters'

        it 'is html safe' do
          expect(subject).to be_html_safe
        end
      end
    end

    context 'for a project cluster' do
      let(:cluster) { create(:cluster, :project) }
      let(:cluster_link) { "<a href=\"#{project_cluster_path(cluster.project, cluster)}\">#{cluster.name}</a>" }

      before do
        cluster.project.add_maintainer(user)
      end

      context 'for the project clusterable' do
        let(:clusterable) { cluster.project }

        it 'returns link for cluster' do
          expect(subject).to eq(cluster_link)
        end
      end
    end
  end

  describe '#provider_label' do
    let(:cluster) { create(:cluster, provider_type: provider_type) }

    subject { described_class.new(cluster).provider_label }

    context 'AWS provider' do
      let(:provider_type) { :aws }

      it { is_expected.to eq('Elastic Kubernetes Service') }
    end

    context 'GCP provider' do
      let(:provider_type) { :gcp }

      it { is_expected.to eq('Google Kubernetes Engine') }
    end
  end

  describe '#provider_management_url' do
    let(:cluster) { provider.cluster }

    subject { described_class.new(cluster).provider_management_url }

    context 'AWS provider' do
      let(:provider) { create(:cluster_provider_aws) }

      it { is_expected.to include(provider.region) }
      it { is_expected.to include(cluster.name) }
    end

    context 'GCP provider' do
      let(:provider) { create(:cluster_provider_gcp) }

      it { is_expected.to include(provider.zone) }
      it { is_expected.to include(cluster.name) }
    end
  end

  describe '#cluster_type_description' do
    subject { described_class.new(cluster).cluster_type_description }

    context 'project_type cluster' do
      it { is_expected.to eq('Project cluster') }
    end

    context 'group_type cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      it { is_expected.to eq('Group cluster') }
    end

    context 'instance_type cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it { is_expected.to eq('Instance cluster') }
    end
  end

  describe '#show_path' do
    subject { described_class.new(cluster).show_path }

    context 'project_type cluster' do
      let(:project) { cluster.project }

      it { is_expected.to eq(project_cluster_path(project, cluster)) }
    end

    context 'group_type cluster' do
      let(:group) { cluster.group }
      let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      it { is_expected.to eq(group_cluster_path(group, cluster)) }
    end

    context 'instance_type cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it { is_expected.to eq(admin_cluster_path(cluster)) }
    end
  end

  describe '#read_only_kubernetes_platform_fields?' do
    subject { described_class.new(cluster).read_only_kubernetes_platform_fields? }

    context 'with a user-provided cluster' do
      let(:cluster) { build_stubbed(:cluster, :provided_by_user) }

      it { is_expected.to be_falsy }
    end

    context 'with a GCP-provided cluster' do
      let(:cluster) { build_stubbed(:cluster, :provided_by_gcp) }

      it { is_expected.to be_truthy }
    end
  end
end
