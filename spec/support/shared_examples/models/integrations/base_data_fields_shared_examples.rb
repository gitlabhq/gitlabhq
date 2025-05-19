# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples Integrations::BaseDataFields do
  subject(:model) { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end

  describe '#activated?' do
    subject(:activated?) { model.activated? }

    context 'with integration' do
      let(:integration) { instance_spy(Integration, activated?: activated) }

      before do
        allow(model).to receive(:integration).and_return(integration)
      end

      context 'with value set to false' do
        let(:activated) { false }

        it { is_expected.to eq(false) }
      end

      context 'with value set to true' do
        let(:activated) { true }

        it { is_expected.to eq(true) }
      end
    end

    context 'without integration' do
      before do
        allow(model).to receive(:integration).and_return(nil)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#to_database_hash' do
    it 'does not include certain attributes' do
      hash = model.to_database_hash

      expect(hash.keys).not_to include(
        'id',
        'service_id',
        'integration_id',
        'created_at',
        'updated_at',
        'instance_integration_id',
        'group_id',
        'project_id',
        'organization_id'
      )
    end
  end

  describe 'validations' do
    context 'when integration is present' do
      before do
        model.integration = build(:integration)
        model.organization_id = 1
      end

      it { is_expected.to be_valid }
    end

    context 'when instance integration is present' do
      before do
        model.instance_integration = build(:instance_integration)
        model.organization_id = 1
      end

      it { is_expected.to be_valid }
    end

    context 'when both instance and non instance integrations are present' do
      it 'validates mutual exclusion correctly' do
        model.integration = build(:integration)
        model.instance_integration = build(:instance_integration)

        expect(model.valid?).to eq(false)
        expect(model.errors.full_messages).to contain_exactly(
          'Integration must be blank',
          'Instance integration must be blank',
          'one of integration or instance_integration must be present',
          'one of project_id, group_id or organization_id must be present'
        )
      end
    end

    context 'when both instance and non instance integrations are missing' do
      it 'validates presence correctly' do
        expect(model.valid?).to eq(false)
        expect(model.errors.full_messages).to contain_exactly(
          'one of integration or instance_integration must be present',
          'one of project_id, group_id or organization_id must be present'
        )
      end
    end

    context 'when sharding key is not set' do
      it 'validates presence correctly' do
        model.integration = build(:integration)

        expect(model.valid?).to eq(false)
        expect(model.errors.full_messages).to contain_exactly(
          'one of project_id, group_id or organization_id must be present'
        )
      end
    end
  end

  describe 'set_sharding_key' do
    context 'when project_id, group_id, or organization_id is already set' do
      it 'does not set new sharding key' do
        integration = build(:integration, project_id: 2)

        model.project_id = 1
        model.integration = integration
        model.valid?

        expect(model.project_id).to eq(1)
      end
    end

    context 'when project_id, group_id, or organization_id are not set' do
      it 'sets the sharding key based on integration' do
        integration = build(:integration, project_id: 1)

        model.integration = integration
        model.valid?

        expect(model.project_id).to eq(1)
      end
    end
  end
end
