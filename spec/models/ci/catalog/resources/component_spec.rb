# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Component, type: :model, feature_category: :pipeline_composition do
  let(:component) { build(:ci_catalog_resource_component) }

  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:version).class_name('Ci::Catalog::Resources::Version') }
  it { is_expected.to have_many(:last_usages).class_name('Ci::Catalog::Resources::Components::LastUsage') }

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let_it_be(:project, freeze: false) { create(:project, :readme, description: 'project description') }
    let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let_it_be(:version, freeze: false) { create(:ci_catalog_resource_version, project: project) }

    let(:valid_items_for_bulk_insertion) do
      build_list(:ci_catalog_resource_component, 10) do |component|
        component.catalog_resource = catalog_resource
        component.version = version
        component.project = project
        component.created_at = Time.zone.now
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_presence_of(:name) }

    context 'when `spec` is valid' do
      it 'returns no errors' do
        component.spec = {
          inputs: {
            website: nil,
            environment: {
              default: 'test'
            },
            tags: {
              type: 'array',
              default: ['tag1']
            }
          }
        }

        expect(component).to be_valid
      end
    end

    context 'when `spec` contains a valid `inputs_order`' do
      it 'returns no errors' do
        component.spec = {
          inputs: { website: nil, environment: nil },
          inputs_order: %w[website environment]
        }

        expect(component).to be_valid
      end
    end

    context 'when `spec` contains an `inputs_order` that is not an array of strings' do
      it 'returns errors' do
        component.spec = { inputs: { website: nil }, inputs_order: ['website', 1] }

        aggregate_failures do
          expect(component).to be_invalid
          expect(component.errors.full_messages).to contain_exactly(
            'Spec must be a valid json schema'
          )
        end
      end
    end

    context 'when `spec` is invalid' do
      it 'returns errors' do
        component.spec = { not_inputs: { boo: '' } }

        aggregate_failures do
          expect(component).to be_invalid
          expect(component.errors.full_messages).to contain_exactly(
            'Spec must be a valid json schema'
          )
        end
      end
    end

    describe '#include_path' do
      let(:component) { create(:ci_catalog_resource_component) }

      it 'generates the correct include path' do
        expected_path = "$CI_SERVER_FQDN/" \
                        "#{component.project.full_path}/" \
                        "#{component.name}@" \
                        "#{component.version.name}"

        expect(component.include_path).to eq(expected_path)
        expect(Gitlab.config.gitlab.server_fqdn).not_to be_nil
      end
    end
  end

  describe '#ordered_inputs' do
    # The input names are deliberately neither in `inputs` order nor in length order, so that the
    # assertions fail if `inputs_order` is not applied.
    let(:inputs) do
      {
        'stage' => { 'default' => 'test' },
        'environment' => { 'description' => 'Deployment target' },
        'n' => { 'type' => 'number' }
      }
    end

    let(:component) { build(:ci_catalog_resource_component, spec: spec) }

    context 'when `spec` contains `inputs_order`' do
      let(:spec) { { 'inputs' => inputs, 'inputs_order' => %w[environment n stage] } }

      it 'returns the inputs in the recorded order' do
        expect(component.ordered_inputs.keys).to eq(%w[environment n stage])
      end

      it 'returns each input with its configuration' do
        expect(component.ordered_inputs['environment']).to eq({ 'description' => 'Deployment target' })
      end
    end

    context 'when `inputs_order` omits an input' do
      let(:spec) { { 'inputs' => inputs, 'inputs_order' => %w[environment stage] } }

      it 'returns the omitted input last' do
        expect(component.ordered_inputs.keys).to eq(%w[environment stage n])
      end
    end

    context 'when `inputs_order` contains an input that no longer exists' do
      let(:spec) { { 'inputs' => inputs, 'inputs_order' => %w[environment removed n stage] } }

      it 'ignores the unknown input' do
        expect(component.ordered_inputs.keys).to eq(%w[environment n stage])
      end
    end

    context 'when `spec` does not contain `inputs_order`' do
      let(:spec) { { 'inputs' => inputs } }

      it 'returns all the inputs' do
        expect(component.ordered_inputs.keys).to match_array(%w[stage environment n])
      end
    end

    context 'when `spec` does not contain `inputs`' do
      let(:spec) { { 'description' => 'A component without inputs' } }

      it 'returns no inputs' do
        expect(component.ordered_inputs).to be_empty
      end
    end
  end
end
