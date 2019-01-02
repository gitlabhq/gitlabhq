# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Prometheus::QueryVariables do
  describe '.call' do
    let(:environment) { create(:environment) }
    let(:slug) { environment.slug }

    subject { described_class.call(environment) }

    it { is_expected.to include(ci_environment_slug: slug) }

    it do
      is_expected.to include(environment_filter:
                             %{container_name!="POD",environment="#{slug}"})
    end

    context 'without deployment platform' do
      it { is_expected.to include(kube_namespace: '') }
    end

    context 'with deployment platform' do
      let(:kube_namespace) { environment.deployment_platform.actual_namespace }

      before do
        create(:cluster, :provided_by_user, projects: [environment.project])
      end

      it { is_expected.to include(kube_namespace: kube_namespace) }
    end
  end
end
