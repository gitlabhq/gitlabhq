# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Ingress do
  include KubernetesHelpers

  let(:ingress) { described_class.new(params) }

  describe '#canary?' do
    subject { ingress.canary? }

    context 'with canary ingress parameters' do
      let(:params) { canary_metadata }

      it { is_expected.to be_truthy }
    end

    context 'with stable ingress parameters' do
      let(:params) { stable_metadata }

      it { is_expected.to be_falsey }
    end
  end

  describe '#canary_weight' do
    subject { ingress.canary_weight }

    context 'with canary ingress parameters' do
      let(:params) { canary_metadata }

      it { is_expected.to eq(50) }
    end

    context 'with stable ingress parameters' do
      let(:params) { stable_metadata }

      it { is_expected.to be_nil }
    end
  end

  describe '#name' do
    subject { ingress.name }

    let(:params) { stable_metadata }

    it { is_expected.to eq('production-auto-deploy') }
  end

  def stable_metadata
    kube_ingress(track: :stable)
  end

  def canary_metadata
    kube_ingress(track: :canary)
  end
end
