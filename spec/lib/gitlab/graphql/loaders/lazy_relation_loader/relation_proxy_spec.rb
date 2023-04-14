# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::LazyRelationLoader::RelationProxy, feature_category: :vulnerability_management do
  describe '#respond_to?' do
    let(:object) { double }
    let(:registry) { instance_double(Gitlab::Graphql::Loaders::LazyRelationLoader::Registry) }
    let(:relation_proxy) { described_class.new(object, registry) }

    subject { relation_proxy.respond_to?(:foo) }

    before do
      allow(registry).to receive(:respond_to?).with(:foo, false).and_return(responds_to?)
    end

    context 'when the registry responds to given method' do
      let(:responds_to?) { true }

      it { is_expected.to be_truthy }
    end

    context 'when the registry does not respond to given method' do
      let(:responds_to?) { false }

      it { is_expected.to be_falsey }
    end
  end
end
