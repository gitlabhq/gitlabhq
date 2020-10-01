# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSettings::UpdateService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:settings) { {} }

  subject(:service) { described_class.new(user, group, settings) }

  describe "#execute" do
    context "group has no namespace_settings" do
      it "builds out a new namespace_settings record" do
        expect do
          service.execute
        end.to change { NamespaceSetting.count }.by(1)
      end
    end

    context "group has a namespace_settings" do
      before do
        create(:namespace_settings, namespace: group)

        service.execute
      end

      it "doesn't create a new namespace_setting record" do
        expect do
          service.execute
        end.not_to change { NamespaceSetting.count }
      end
    end
  end
end
