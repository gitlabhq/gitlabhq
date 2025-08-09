# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::LabelsController, :enable_admin_mode, :with_current_organization, feature_category: :team_planning do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization1) { create(:organization) }
  let_it_be_with_reload(:label1) { create(:admin_label, organization: current_organization) }
  let_it_be_with_reload(:label2) { create(:admin_label, organization: organization1) }

  before do
    sign_in(admin)
  end

  describe 'GET #index', :aggregate_failures do
    it 'returns all label templates scoped to the current organization', :aggregate_failures do
      get admin_labels_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(label1.title)
      expect(response.body).not_to include(label2.title)
    end

    context 'when template_labels_scoped_by_org feature flag is disabled' do
      before do
        stub_feature_flags(template_labels_scoped_by_org: false)
      end

      it 'returns all label templates from all organizations', :aggregate_failures do
        get admin_labels_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(label1.title)
        expect(response.body).to include(label2.title)
      end
    end
  end

  describe 'POST #create' do
    it 'creates a template label', :aggregate_failures do
      expect do
        post admin_labels_path, params: { label: { title: 'Foo', color: '#FFFFFF', description: 'bar' } }
      end.to change { Label.count }.by(1)

      created_label = Label.reorder(:id).last
      expect(created_label.title).to eq('Foo')
      expect(created_label.color).to eq(Gitlab::Color.of('#FFFFFF'))
      expect(created_label.description).to eq('bar')
      expect(created_label.template).to be(true)
      expect(created_label.organization).to eq(current_organization)
      expect(created_label.project).to be_nil
      expect(created_label.group).to be_nil

      expect(response).to have_gitlab_http_status(:found)
    end
  end

  describe 'PUT #update' do
    context 'when label does not belong to current organization' do
      it 'does not find the label' do
        expect do
          put admin_label_path(label2), params: { label: { title: 'Foo' } }
        end.to not_change { label2.reload.title }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when template_labels_scoped_by_org feature flag is disabled' do
        before do
          stub_feature_flags(template_labels_scoped_by_org: false)
        end

        it 'updates the label' do
          expect do
            put admin_label_path(label2), params: { label: { title: 'Foo' } }
          end.to change { label2.reload.title }.to('Foo')

          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    context 'when the label is missing an organization_id' do
      let(:label) do
        # We can no longer create invalid test data due to the contraint, but we know it exists in production
        Label.connection.execute(<<~SQL)
          ALTER TABLE labels DROP CONSTRAINT check_2d9a8c1bca;
        SQL

        admin_label = build(:admin_label, organization_id: nil)
        admin_label.save!(validate: false)

        Label.connection.execute(<<~SQL)
          ALTER TABLE labels
            ADD CONSTRAINT check_2d9a8c1bca CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
        SQL

        admin_label
      end

      before do
        stub_feature_flags(template_labels_scoped_by_org: false)
      end

      it 'sets the organization_id' do
        expect do
          put admin_label_path(label), params: { label: { title: 'Foo' } }
        end.to change { label.reload.organization }.from(nil).to(current_organization).and(
          change { label.reload.title }.from(label.title).to('Foo')
        )
      end
    end
  end
end
