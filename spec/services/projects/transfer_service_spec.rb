require 'spec_helper'

describe Projects::TransferService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      group.add_owner(user)
      @result = transfer_project(project, user, new_namespace_id: group.id)
    end

    it { expect(@result).to be_truthy }
    it { expect(project.namespace).to eq(group) }
  end

  context 'namespace -> no namespace' do
    before do
      @result = transfer_project(project, user, new_namespace_id: nil)
    end

    it { expect(@result).not_to be_nil } # { result.should be_false } passes on nil
    it { expect(@result).to be_falsey }
    it { expect(project.namespace).to eq(user.namespace) }
  end

  context 'namespace -> not allowed namespace' do
    before do
      @result = transfer_project(project, user, new_namespace_id: group.id)
    end

    it { expect(@result).not_to be_nil } # { result.should be_false } passes on nil
    it { expect(@result).to be_falsey }
    it { expect(project.namespace).to eq(user.namespace) }
  end

  def transfer_project(project, user, params)
    Projects::TransferService.new(project, user, params).execute
  end
end
