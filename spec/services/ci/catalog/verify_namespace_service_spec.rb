# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::VerifyNamespaceService, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:group_project) { create(:project, group: group) }
  let_it_be(:group_project_resource) { create(:ci_catalog_resource, :published, project: group_project) }

  let_it_be(:subgroup_project) { create(:project, group: subgroup) }
  let_it_be(:subgroup_project_published_resource) do
    create(:ci_catalog_resource, :published, project: subgroup_project)
  end

  let_it_be(:subgroup_public_project) { create(:project, :public, group: subgroup) }
  let_it_be(:subgroup_public_project_resource) do
    create(:ci_catalog_resource, :published, project: subgroup_public_project)
  end

  let_it_be(:another_group) { create(:group) }
  let_it_be(:another_group_private_project) { create(:project, group: another_group) }
  let_it_be(:another_group_private_project_resource) do
    create(:ci_catalog_resource, project: another_group_private_project)
  end

  let_it_be(:another_group_published_project) { create(:project, group: another_group) }
  let_it_be(:another_group_published_project_resource) do
    create(:ci_catalog_resource, :published, project: another_group_published_project)
  end

  describe '#execute' do
    context 'when namespace passed in is not a root namespace' do
      it 'is not valid' do
        response = described_class.new(subgroup, 'gitlab_maintained').execute

        expect(response.message).to eq('Please pass in the root namespace.')
      end
    end

    context 'when root namespace is passed' do
      context 'when unknown verification level is being set' do
        it 'is not valid' do
          response = described_class.new(group, 'unknown').execute

          expect(response.message).to eq('Please pass in a valid verification level: gitlab_maintained, ' \
                                         'gitlab_partner_maintained, verified_creator_maintained, unverified.')
        end
      end

      ::Ci::Catalog::VerifiedNamespace::VERIFICATION_LEVELS.each_key do |level|
        context "when #{level} verification level is being set" do
          let(:verification_level) { level.to_s }

          it 'creates an instance of ::Ci::Catalog::VerifiedNamespace' do
            expect do
              described_class.new(group, verification_level).execute
            end.to change { ::Ci::Catalog::VerifiedNamespace.count }.by(1)
          end

          it 'updates the verification level for all catalog resources under the given namespace' do
            response = described_class.new(group, verification_level).execute

            expect(response).to be_success

            expect(group_project_resource.reload.verification_level).to eq(verification_level)
            expect(subgroup_project_published_resource.reload.verification_level).to eq(verification_level)
            expect(subgroup_public_project_resource.reload.verification_level).to eq(verification_level)

            expect(another_group_published_project_resource.reload.verification_level).to eq('unverified')
          end
        end
      end
    end

    context 'when updating existing verified namespace' do
      let(:new_verification_level) { 'gitlab_partner_maintained' }

      it 'does not create a new instance of VerifiedNamespace' do
        ::Ci::Catalog::VerifiedNamespace.find_or_create_by!(namespace: group,
          verification_level: 'gitlab_maintained')

        expect do
          described_class.new(group, new_verification_level).execute
        end.not_to change { ::Ci::Catalog::VerifiedNamespace.count }
      end

      it 'updates verification level on the existing verified namespace' do
        verified_namespace =
          ::Ci::Catalog::VerifiedNamespace.find_or_create_by!(namespace: group,
            verification_level: 'gitlab_maintained')

        described_class.new(group, new_verification_level).execute

        expect(verified_namespace.reload.verification_level).to eq(new_verification_level)
      end

      it 'updates the verification level on catalog resources' do
        ::Ci::Catalog::VerifiedNamespace.find_or_create_by!(namespace: group,
          verification_level: 'gitlab_maintained')

        response = described_class.new(group, new_verification_level).execute

        expect(response).to be_success

        expect(group_project_resource.reload.verification_level).to eq(new_verification_level)
        expect(subgroup_project_published_resource.reload.verification_level).to eq(new_verification_level)
        expect(subgroup_public_project_resource.reload.verification_level).to eq(new_verification_level)

        expect(another_group_published_project_resource.reload.verification_level).to eq('unverified')
      end
    end
  end
end
