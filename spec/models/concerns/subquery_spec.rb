# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subquery do
  let_it_be(:projects) { create_list :project, 3 }
  let_it_be(:project_ids) { projects.map(&:id) }
  let(:relation) { Project.where(id: projects) }

  subject { relation.subquery(:id) }

  shared_examples 'subquery as array values' do
    it { is_expected.to match_array project_ids }
    specify { expect { subject }.not_to make_queries }
  end

  shared_examples 'subquery as relation' do
    it { is_expected.to be_a ActiveRecord::Relation }
    specify { expect { subject.load }.to make_queries }
  end

  shared_context 'when array size exceeds max_limit' do
    subject { relation.subquery(:id, max_limit: 1) }
  end

  context 'when relation is not loaded' do
    it_behaves_like 'subquery as relation'

    context 'when array size exceeds max_limit' do
      include_context 'when array size exceeds max_limit'

      it_behaves_like 'subquery as relation'
    end
  end

  context 'when relation is loaded' do
    before do
      relation.load
    end

    it_behaves_like 'subquery as array values'

    context 'when array size exceeds max_limit' do
      include_context 'when array size exceeds max_limit'

      it_behaves_like 'subquery as relation'
    end

    context 'with a select' do
      let(:relation) { Project.where(id: projects).select(:id) }

      it_behaves_like 'subquery as array values'

      context 'and querying with an unloaded column' do
        subject { relation.subquery(:namespace_id) }

        it { expect { subject }.to raise_error(ActiveModel::MissingAttributeError) }
      end
    end
  end
end
