# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RateLimit::Target, feature_category: :rate_limiting do
  describe '#cache_key' do
    it 'joins the type and the identifier', :aggregate_failures do
      expect(described_class.new(type: :route, identifier: 'gitlab-org/gitlab').cache_key)
        .to eq('route:gitlab-org/gitlab')
      expect(described_class.new(type: :project, identifier: '278964').cache_key).to eq('project:278964')
      expect(described_class.new(type: :group, identifier: '9970').cache_key).to eq('group:9970')
    end
  end

  describe '#root_id' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }

    def root_id_for(type, identifier)
      described_class.new(type: type, identifier: identifier.to_s).root_id
    end

    # A type added without a branch in #root_id resolves to nil, which TargetNamespace
    # caches as a miss, dropping that kind from the namespace rules with nothing raised.
    it 'folds every target type onto the root namespace', :aggregate_failures do
      resolved = {
        route: root_id_for(:route, project.full_path),
        project: root_id_for(:project, project.id),
        group: root_id_for(:group, subgroup.id)
      }

      expect(resolved.keys).to match_array(described_class::TYPES)
      expect(resolved.values).to all(eq(group.id))
    end

    it 'returns nothing for an identifier that names nothing', :aggregate_failures do
      expect(root_id_for(:route, 'no/such/namespace')).to be_nil
      expect(root_id_for(:project, non_existing_record_id)).to be_nil
      expect(root_id_for(:group, non_existing_record_id)).to be_nil
    end
  end

  it 'rejects a type it cannot resolve, rather than silently caching a miss' do
    expect { described_class.new(type: :snippet, identifier: '1') }
      .to raise_error(ArgumentError, 'unknown target type: snippet')
  end
end
