require 'spec_helper'

describe Projects::TransferService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      group.add_owner(user)
      @result = transfer_project(project, user, namespace_id: group.id)
    end

    it { @result.should be_true }
    it { project.namespace.should == group }
  end

  context 'namespace -> no namespace' do
    before do
      @result = transfer_project(project, user, namespace_id: nil)
    end

    it { @result.should_not be_nil } # { result.should be_false } passes on nil
    it { @result.should be_false }
    it { project.namespace.should == user.namespace }
  end

  context 'namespace -> not allowed namespace' do
    before do
      @result = transfer_project(project, user, namespace_id: group.id)
    end

    it { @result.should_not be_nil } # { result.should be_false } passes on nil
    it { @result.should be_false }
    it { project.namespace.should == user.namespace }
  end

  def transfer_project(project, user, params)
    Projects::TransferService.new(project, user, params).execute
  end
end
