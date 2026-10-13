# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Routing::OrganizationsHelper, feature_category: :organization do
  describe '.organization_scoped_route?' do
    it 'is true for /o/ paths and false otherwise' do
      expect(described_class.organization_scoped_route?('/o/my-org/my-group')).to be(true)
      expect(described_class.organization_scoped_route?('/my-group')).to be(false)
      expect(described_class.organization_scoped_route?(nil)).to be(false)
    end
  end

  describe '.unscoped_path' do
    using RSpec::Parameterized::TableSyntax

    where(:path, :expected) do
      '/o/my-org/my-group/my-project/-/issues/1/realtime_changes' | '/my-group/my-project/-/issues/1/realtime_changes'
      '/o/my-org/groups/my-group/-/epics/1/realtime_changes'      | '/groups/my-group/-/epics/1/realtime_changes'
      '/o/my-org/'                                                | '/'
      '/o/my-org'                                                 | '/o/my-org'
      '/my-group/my-project/-/issues/1/realtime_changes'          | '/my-group/my-project/-/issues/1/realtime_changes'
      '/api/graphql:pipelines/id/5'                               | '/api/graphql:pipelines/id/5'
      nil                                                         | nil
    end

    with_them do
      it { expect(described_class.unscoped_path(path)).to eq(expected) }
    end

    # Treating /o/my-org/g/p and /g/p as one resource is only correct while a
    # namespace path names one resource instance-wide. Once uniqueness is per
    # Organization, see https://gitlab.com/gitlab-org/gitlab/-/work_items/630141.
    context 'when relying on instance-wide unique namespace paths' do
      let(:message) do
        'Namespace paths are no longer unique instance-wide. Callers of unscoped_path must key on ' \
          'the Organization too, see https://gitlab.com/gitlab-org/gitlab/-/work_items/630141'
      end

      it 'has a unique database index on routes.path alone' do
        index = Route.connection.indexes(:routes).find { |i| i.unique && i.columns == ['path'] }

        expect(index).to be_present, message
      end

      it 'validates Route#path uniqueness without a scope' do
        validator = Route.validators_on(:path).grep(ActiveRecord::Validations::UniquenessValidator).first

        expect(validator&.options&.dig(:scope)).to be_nil, message
      end
    end
  end
end
