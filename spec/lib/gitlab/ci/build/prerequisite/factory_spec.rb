# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Prerequisite::Factory do
  let(:build) { create(:ci_build) }

  describe '.for_build' do
    let(:kubernetes_namespace) do
      instance_double(
        Gitlab::Ci::Build::Prerequisite::KubernetesNamespace,
        unmet?: unmet)
    end

    let(:managed_resource) do
      instance_double(
        Gitlab::Ci::Build::Prerequisite::ManagedResource,
        unmet?: unmet)
    end

    subject { described_class.new(build).unmet }

    before do
      expect(Gitlab::Ci::Build::Prerequisite::KubernetesNamespace)
        .to receive(:new).with(build).and_return(kubernetes_namespace)
      expect(Gitlab::Ci::Build::Prerequisite::ManagedResource)
        .to receive(:new).with(build).and_return(managed_resource)
    end

    context 'prerequisite is unmet' do
      let(:unmet) { true }

      it { is_expected.to match_array [kubernetes_namespace, managed_resource] }
    end

    context 'prerequisite is met' do
      let(:unmet) { false }

      it { is_expected.to be_empty }
    end
  end
end
