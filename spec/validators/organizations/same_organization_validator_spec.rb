# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::SameOrganizationValidator, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project, organization: create(:organization)) }
  let_it_be(:source) { create(:work_item, project: project) }
  let_it_be(:same_org_target) { create(:work_item, project: project) }
  let_it_be(:cross_org_target) { create(:work_item, project: other_project) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :source, :target

      validates_with Organizations::SameOrganizationValidator

      def self.name
        'TestSameOrgLink'
      end
    end
  end

  subject(:record) { model_class.new(source: source, target: target) }

  context 'when source and target share an organization' do
    let(:target) { same_org_target }

    it { is_expected.to be_valid }
  end

  context 'when source and target are in different organizations' do
    let(:target) { cross_org_target }

    it 'is invalid with a clear message on the target' do
      expect(record).to be_invalid
      expect(record.errors.messages[:target]).to include('must belong to the same organization.')
    end

    context 'when the prevent_cross_organization_work_item_actions flag is disabled' do
      before do
        stub_feature_flags(prevent_cross_organization_work_item_actions: false)
      end

      it { is_expected.to be_valid }
    end
  end

  context 'with custom left/right accessors and message' do
    let(:model_class) do
      Class.new do
        include ActiveModel::Model

        attr_accessor :parent, :child

        validates_with Organizations::SameOrganizationValidator, left: :parent, right: :child, message: 'custom message'

        def self.name
          'TestCustomSameOrgLink'
        end
      end
    end

    subject(:record) { model_class.new(parent: source, child: cross_org_target) }

    it 'adds the custom message on the right accessor' do
      expect(record).to be_invalid
      expect(record.errors.messages[:child]).to include('custom message')
    end
  end
end
