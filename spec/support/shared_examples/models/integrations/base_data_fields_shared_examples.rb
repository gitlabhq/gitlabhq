# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples Integrations::BaseDataFields do
  using RSpec::Parameterized::TableSyntax

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

    it 'validates presence correctly' do
      expect(model.valid?).to eq(false)
      expect(model.errors.full_messages).to contain_exactly(
        "Integration can't be blank",
        'one of project_id, group_id or organization_id must be present'
      )
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

    where(:project_id, :group_id, :organization_id, :valid) do
      1    | nil  | nil | true
      nil  | 1    | nil | true
      nil  | nil  | 1   | true
      nil  | nil  | nil | false
      1    | 1    | 1   | false
      nil  | 1    | 1   | false
      1    | 1    | nil | false
      1    | nil  | 1   | false
    end

    with_them do
      it 'validates data_fields sharding key presence' do
        model.assign_attributes(
          project_id: project_id,
          group_id: group_id,
          organization_id: organization_id,
          integration: build(:integration)
        )

        expect(model.valid?).to eq(valid)
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
