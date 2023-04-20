# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::LazyRelationLoader::Registry, feature_category: :vulnerability_management do
  describe '#respond_to?' do
    let(:relation) { Project.all }
    let(:registry) { described_class.new(relation) }

    subject { registry.respond_to?(method_name) }

    context 'when the relation responds to given method' do
      let(:method_name) { :sorted_by_updated_asc }

      it { is_expected.to be_truthy }
    end

    context 'when the relation does not respond to given method' do
      let(:method_name) { :this_method_does_not_exist }

      it { is_expected.to be_falsey }
    end
  end
end
