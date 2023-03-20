# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTags::UpdateService, feature_category: :compliance_management do
  let(:protected_tag) { create(:protected_tag) }
  let(:project) { protected_tag.project }
  let(:user) { project.first_owner }
  let(:params) { { name: new_name } }

  describe '#execute' do
    let(:new_name) { 'new protected tag name' }
    let(:result) { service.execute(protected_tag) }

    subject(:service) { described_class.new(project, user, params) }

    it 'updates a protected tag' do
      expect(result.reload.name).to eq(params[:name])
    end

    context 'when updating protected tag with a name that contains HTML tags' do
      let(:new_name) { 'foo<b>bar<\b>' }
      let(:result) { service.execute(protected_tag) }

      subject(:service) { described_class.new(project, user, params) }

      it 'updates a protected tag' do
        expect(result.reload.name).to eq(new_name)
      end
    end

    context 'without admin_project permissions' do
      let(:user) { create(:user) }

      it "raises error" do
        expect { service.execute(protected_tag) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
