# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Exclusions::DestroyService, feature_category: :source_code_management do
  let(:integration_name) { 'beyond_identity' }
  let_it_be(:admin_user) { create(:admin) }
  let(:current_user) { admin_user }
  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project, :in_subgroup) }
  let(:projects) { [project] }
  let(:groups) { [] }
  let(:service) do
    described_class.new(current_user: current_user, integration_name: integration_name, projects: projects,
      groups: groups)
  end

  describe '#execute', :enable_admin_mode do
    subject(:execute) { service.execute }

    it_behaves_like 'performs exclusions service validations'

    context 'when there is an exclusion for the project exists' do
      let!(:exclusion) do
        create(:beyond_identity_integration, active: false, project: project, instance: false, inherit_from_id: nil)
      end

      it 'deletes the exclusion' do
        expect { execute }.to change { Integration.count }.from(1).to(0)
        expect(execute.payload).to contain_exactly(exclusion)
      end

      context 'and there is an exclusion for a group' do
        let!(:group_exclusion) do
          create(:beyond_identity_integration, active: false, group: other_project.root_namespace, instance: false,
            inherit_from_id: nil)
        end

        context 'and the exclusion for that group is to be destroyed' do
          let(:groups) { [group_exclusion.group] }

          it 'deletes the exclusions' do
            expect { execute }.to change { Integration.count }.from(2).to(0)
            expect(execute.payload).to contain_exactly(exclusion, group_exclusion)
          end
        end

        context 'and exclusions to be destroyed are inherited' do
          let!(:inherited_project_exclusion) do
            create(:beyond_identity_integration, active: false, project: other_project, instance: false,
              inherit_from_id: group_exclusion.id)
          end

          let!(:inherited_group_exclusion) do
            create(:beyond_identity_integration, active: false, group: other_project.group, instance: false,
              inherit_from_id: group_exclusion.id)
          end

          let(:projects) { [other_project] }
          let(:groups) { [other_project.group] }

          it 'does not delete the progagated settings' do
            expect { execute }.not_to change { Integration.count }
            expect(execute.payload).to be_empty
          end
        end
      end

      context 'and the integration is active for the instance' do
        let!(:instance_integration) { create(:beyond_identity_integration) }

        it 'updates the exclusion integration to be active' do
          expect { execute }.to change { exclusion.reload.active }.from(false).to(true)
          expect(exclusion.inherit_from_id).to eq(instance_integration.id)
        end

        context 'and there is an exclusion for a group' do
          let!(:group_exclusion) do
            create(:beyond_identity_integration, active: false, group: other_project.root_namespace, instance: false,
              inherit_from_id: nil)
          end

          context 'and the exclusion for that group is to be destroyed' do
            let(:groups) { [group_exclusion.group] }

            it 'updates the exclusion integrations to be active' do
              expect { execute }.to change { exclusion.reload.active }.from(false).to(true)
                .and change { exclusion.inherit_from_id }.from(nil).to(instance_integration.id)
                .and change { group_exclusion.reload.active }.from(false).to(true)
                .and change { group_exclusion.inherit_from_id }.from(nil).to(instance_integration.id)
            end
          end

          context 'and exclusions to be deleted are inherited' do
            let!(:inherited_project_exclusion) do
              create(:beyond_identity_integration, active: false, project: other_project, instance: false,
                inherit_from_id: group_exclusion.id)
            end

            let!(:inherited_group_exclusion) do
              create(:beyond_identity_integration, active: false, group: other_project.group, instance: false,
                inherit_from_id: group_exclusion.id)
            end

            let(:projects) { [other_project] }
            let(:groups) { [other_project.group] }

            it 'does not update inherited exclusions' do
              execute
              expect(inherited_project_exclusion.reload).not_to be_activated
              expect(inherited_group_exclusion.reload).not_to be_activated
            end
          end
        end
      end
    end
  end
end
