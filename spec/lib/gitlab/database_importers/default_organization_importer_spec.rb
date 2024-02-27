# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::DefaultOrganizationImporter, feature_category: :cell do
  describe '#create_default_organization' do
    let(:default_id) { Organizations::Organization::DEFAULT_ORGANIZATION_ID }

    subject { described_class.create_default_organization }

    context 'when default organization does not exists' do
      it 'creates a default organization' do
        expect(Organizations::Organization.find_by(id: default_id)).to be_nil

        subject

        default_org = Organizations::Organization.find(default_id)

        expect(default_org.name).to eq('Default')
        expect(default_org.path).to eq('default')
        expect(default_org).to be_public
      end
    end

    context 'when default organization exists' do
      let!(:default_org) { create(:organization, :default) }

      it 'does not create another organization' do
        expect { subject }.not_to change { Organizations::Organization.count }
      end
    end
  end
end
