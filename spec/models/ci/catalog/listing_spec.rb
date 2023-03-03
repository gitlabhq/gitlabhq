# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Listing, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project_1) { create(:project, namespace: namespace) }
  let_it_be(:project_2) { create(:project, namespace: namespace) }
  let_it_be(:project_3) { create(:project) }

  let(:list) { described_class.new(namespace) }

  describe '#new' do
    context 'when namespace is not a root namespace' do
      let(:namespace) { create(:group, :nested) }

      it 'raises an exception' do
        expect { list }.to raise_error(ArgumentError, 'Namespace is not a root namespace')
      end
    end
  end

  describe '#resources' do
    subject(:resources) { list.resources }

    context 'when the namespace has no catalog resources' do
      it { is_expected.to be_empty }
    end

    context 'when the namespace has catalog resources' do
      let!(:resource) { create(:catalog_resource, project: project_1) }

      it 'contains only catalog resources for projects in that namespace' do
        is_expected.to contain_exactly(resource)
      end
    end
  end
end
