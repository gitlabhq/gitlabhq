# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSettings::UpdateService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:settings) { {} }

  subject(:service) { described_class.new(user, group, settings) }

  describe "#execute" do
    context "group has no namespace_settings" do
      before do
        group.namespace_settings.destroy!
      end

      it "builds out a new namespace_settings record" do
        expect do
          service.execute
        end.to change { NamespaceSetting.count }.by(1)
      end
    end

    context "group has a namespace_settings" do
      before do
        service.execute
      end

      it "doesn't create a new namespace_setting record" do
        expect do
          service.execute
        end.not_to change { NamespaceSetting.count }
      end
    end

    context "updating :default_branch_name" do
      let(:example_branch_name) { "example_branch_name" }
      let(:settings) { { default_branch_name: example_branch_name } }

      it "changes settings" do
        expect { service.execute }
          .to change { group.namespace_settings.default_branch_name }
          .from(nil).to(example_branch_name)
      end
    end

    context "updating :resource_access_token_creation_allowed" do
      let(:settings) { { resource_access_token_creation_allowed: false } }

      context 'when user is a group owner' do
        before do
          group.add_owner(user)
        end

        it "changes settings" do
          expect { service.execute }
            .to change { group.namespace_settings.resource_access_token_creation_allowed }
            .from(true).to(false)
        end
      end

      context 'when user is not a group owner' do
        before do
          group.add_developer(user)
        end

        it "does not change settings" do
          expect { service.execute }.not_to change { group.namespace_settings.resource_access_token_creation_allowed }
        end

        it 'returns the group owner error' do
          service.execute
          expect(group.namespace_settings.errors.messages[:resource_access_token_creation_allowed]).to include('can only be changed by a group admin.')
        end
      end
    end
  end
end
