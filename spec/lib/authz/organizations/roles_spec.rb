# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::Organizations::Roles, feature_category: :system_access do
  describe '.organization_admin_uuid' do
    before do
      allow(Gitlab::Glaz).to receive(:roles).and_return(roles)
    end

    context 'when the catalogue includes the role' do
      let(:roles) do
        [
          { id: '019ed9d4-7d53-7b5c-8653-1ceac0c48b14', name: 'Artifact Viewer', permissions: [] },
          { id: '019ed9d7-920d-72eb-a0ff-117122219c2a', name: 'Organization Administrator', permissions: [] }
        ]
      end

      it 'returns the id of the Organization Administrator role' do
        expect(described_class.organization_admin_uuid).to eq('019ed9d7-920d-72eb-a0ff-117122219c2a')
      end
    end

    context 'when the catalogue does not include the role' do
      let(:roles) { [] }

      it 'returns nil' do
        expect(described_class.organization_admin_uuid).to be_nil
      end
    end
  end
end
