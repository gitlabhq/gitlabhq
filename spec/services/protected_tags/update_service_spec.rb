require 'spec_helper'

describe ProtectedTags::UpdateService do
  let(:protected_tag) { create(:protected_tag) }
  let(:project) { protected_tag.project }
  let(:user) { project.owner }
  let(:params) { { name: 'new protected tag name' } }

  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    it 'updates a protected tag' do
      result = service.execute(protected_tag)

      expect(result.reload.name).to eq(params[:name])
    end

    context 'without admin_project permissions' do
      let(:user) { create(:user) }

      it "raises error" do
        expect { service.execute(protected_tag) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
