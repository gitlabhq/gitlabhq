# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::Custom::Type, feature_category: :team_planning do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:namespace) { create(:group) }

  describe 'validations' do
    subject(:work_item_custom_type) { build(:work_item_custom_type) }

    describe 'single_parent_set' do
      context 'when neither organization nor namespace is set' do
        subject(:work_item_custom_type) { build(:work_item_custom_type, organization: nil, namespace: nil) }

        it 'is invalid' do
          expect(work_item_custom_type).to be_invalid
          expect(work_item_custom_type.errors[:base]).to include(
            'Exactly one of namespace_id, organization_id must be present'
          )
        end
      end

      context 'when both organization and namespace are set' do
        before do
          work_item_custom_type.organization = organization
          work_item_custom_type.namespace = namespace
        end

        it 'is invalid' do
          expect(work_item_custom_type).to be_invalid
        end
      end

      context 'when only organization is set' do
        subject { build(:work_item_custom_type, organization: create(:organization), namespace: nil) }

        it { is_expected.to be_valid }
      end

      context 'when only namespace is set' do
        subject { build(:work_item_custom_type, organization: nil, namespace: create(:group)) }

        it { is_expected.to be_valid }
      end
    end

    describe 'name uniqueness' do
      context 'when scoped to organization' do
        before do
          create(:work_item_custom_type, organization: organization, namespace: nil, name: 'Feature')
        end

        it 'validates uniqueness within the same organization' do
          duplicate = build(:work_item_custom_type, organization: organization, namespace: nil, name: 'Feature')
          expect(duplicate).to be_invalid
          expect(duplicate.errors[:name]).to include('has already been taken')
        end

        it 'allows same name in different organization' do
          other_org = create(:organization)
          type = build(:work_item_custom_type, organization: other_org, namespace: nil, name: 'Feature')
          expect(type).to be_valid
        end
      end

      context 'when scoped to namespace' do
        before do
          create(:work_item_custom_type, namespace: namespace, name: 'Feature')
        end

        it 'validates uniqueness within the same namespace' do
          duplicate = build(:work_item_custom_type, namespace: namespace, name: 'Feature')
          expect(duplicate).to be_invalid
          expect(duplicate.errors[:name]).to include('has already been taken')
        end

        it 'allows same name in different namespace' do
          other_namespace = create(:group)
          type = build(:work_item_custom_type, namespace: other_namespace, name: 'Feature')
          expect(type).to be_valid
        end
      end
    end

    describe 'name uniqueness against system-defined types' do
      it 'prevents using system-defined type names' do
        type = build(:work_item_custom_type, organization: organization, namespace: nil, name: 'Task')

        expect(type).to be_invalid
        expect(type.errors[:name]).to include("'Task' is already taken")
      end

      it 'allows names that are not system-defined' do
        type = build(:work_item_custom_type, organization: organization, namespace: nil, name: 'Feature')
        expect(type).to be_valid
      end

      it 'skips validation when name is blank' do
        type = build(:work_item_custom_type, organization: organization, namespace: nil, name: '')
        type.valid?
        expect(type.errors[:name]).to include("can't be blank")
      end

      context 'when converted from system-defined type' do
        it 'allows keeping the same name as the system-defined type' do
          type = build(:work_item_custom_type, :converted_from_issue,
            organization: organization, namespace: nil, name: 'Issue')
          expect(type).to be_valid
        end

        it 'allows keeping the same name with different casing' do
          type = build(:work_item_custom_type, :converted_from_incident,
            organization: organization, namespace: nil, name: 'INCIDENT')
          expect(type).to be_valid
        end

        it 'prevents renaming to a different system-defined type name' do
          type = build(:work_item_custom_type, :converted_from_task,
            organization: organization, namespace: nil, name: 'Issue')
          expect(type).to be_invalid
          expect(type.errors[:name]).to include("'Issue' is already taken")
        end

        it 'allows renaming to a non-system-defined name' do
          type = build(:work_item_custom_type, :converted_from_task,
            organization: organization, namespace: nil, name: 'Feature')
          expect(type).to be_valid
        end

        context 'when another converted type with changed name exists' do
          before do
            create(:work_item_custom_type, :converted_from_issue,
              organization: organization, namespace: nil, name: 'Custom Issue')
          end

          it 'allows reusing the system-defined name of the existing converted type' do
            type = build(:work_item_custom_type, :converted_from_task,
              organization: organization, namespace: nil, name: 'Issue')
            expect(type).to be_valid
          end
        end
      end
    end

    describe 'max types per parent limit' do
      before do
        stub_const("#{described_class}::MAX_TYPE_PER_PARENT", 1)
      end

      context 'for organization' do
        let_it_be(:existing_type) { create(:work_item_custom_type, organization: organization, namespace: nil) }

        it 'is invalid when exceeding maximum allowed types' do
          type = build(:work_item_custom_type, organization: organization, namespace: nil)

          expect(type).to be_invalid
          expect(type.errors[:organization]).to include('can only have a maximum of 1 work item types.')
        end

        it 'allows updating existing types without hitting the limit' do
          existing_type.name = 'Updated Name'

          expect(existing_type).to be_valid
        end
      end

      context 'for namespace' do
        let_it_be(:existing_type) { create(:work_item_custom_type, namespace: namespace) }

        it 'is invalid when exceeding maximum allowed types' do
          type = build(:work_item_custom_type, namespace: namespace)

          expect(type).to be_invalid
          expect(type.errors[:namespace]).to include('can only have a maximum of 1 work item types.')
        end

        it 'allows updating existing types without hitting the limit' do
          existing_type.name = 'Updated Name'

          expect(existing_type).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '.for_organization' do
      before do
        create(:work_item_custom_type, organization: organization, namespace: nil, name: 'Type 1')
        create(:work_item_custom_type, organization: create(:organization), namespace: nil, name: 'Type 2')
        create(:work_item_custom_type, namespace: namespace, name: 'Type 3')
      end

      it 'returns only types for the given organization' do
        types = described_class.for_organization(organization)
        expect(types.pluck(:name)).to contain_exactly('Type 1')
      end
    end

    describe '.for_namespace' do
      before do
        create(:work_item_custom_type, namespace: namespace, name: 'Type 1')
        create(:work_item_custom_type, namespace: create(:group), name: 'Type 2')
        create(:work_item_custom_type, organization: organization, namespace: nil, name: 'Type 3')
      end

      it 'returns only types for the given namespace' do
        types = described_class.for_namespace(namespace)
        expect(types.pluck(:name)).to contain_exactly('Type 1')
      end
    end

    describe '.order_by_name_asc' do
      before do
        create(:work_item_custom_type, organization: organization, namespace: nil, name: 'Zebra')
        create(:work_item_custom_type, organization: organization, namespace: nil, name: 'apple')
        create(:work_item_custom_type, organization: organization, namespace: nil, name: 'Banana')
      end

      it 'orders by name case-insensitively' do
        names = described_class.order_by_name_asc.pluck(:name)
        expect(names).to eq(%w[apple Banana Zebra])
      end
    end
  end

  describe '#parent' do
    context 'when organization is set' do
      let(:type) { create(:work_item_custom_type, organization: organization, namespace: nil) }

      it 'returns the organization' do
        expect(type.parent).to eq(organization)
      end
    end

    context 'when namespace is set' do
      let(:type) { create(:work_item_custom_type, namespace: namespace) }

      it 'returns the namespace' do
        expect(type.parent).to eq(namespace)
      end
    end
  end

  describe '#delegation_source' do
    context 'when converted from system-defined type' do
      let(:type) do
        create(:work_item_custom_type,
          converted_from_system_defined_type_identifier: 2)
      end

      it 'returns the system-defined type' do
        expect(type.base_type).to eq("incident")
      end
    end

    context 'when new custom type' do
      let(:type) { create(:work_item_custom_type) }

      it 'defaults to issue base type' do
        expect(type.base_type).to eq("issue")
      end
    end
  end

  describe '#strip_whitespaces' do
    it 'strips whitespaces from name' do
      work_item_custom_type = build(:work_item_custom_type, name: '  Feature  ')

      work_item_custom_type.valid?

      expect(work_item_custom_type.name).to eq("Feature")
    end
  end

  describe '#to_global_id' do
    context 'when converted from system-defined type' do
      let(:type) do
        create(:work_item_custom_type,
          converted_from_system_defined_type_identifier: 1)
      end

      it 'uses the system-defined type ID in the global ID' do
        gid = type.to_global_id
        expect(gid.model_name).to eq('WorkItems::Type')
        expect(gid.model_id.to_i).to eq(1)
      end
    end

    context 'when new custom type' do
      let(:type) { create(:work_item_custom_type) }

      it 'uses the custom type ID in the global ID' do
        gid = type.to_global_id
        expect(gid.model_name).to eq('WorkItems::TypesFramework::Custom::Type')
        expect(gid.model_id.to_i).to eq(type.id)
      end
    end
  end

  describe 'enum' do
    it 'defines icon_name enum' do
      type = create(:work_item_custom_type, icon_name: :work_item_feature)
      expect(type.icon_name).to eq('work_item_feature')
      expect(type.work_item_feature?).to be_truthy
    end
  end
end
