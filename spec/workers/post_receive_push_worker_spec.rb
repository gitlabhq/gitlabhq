require 'spec_helper'

describe PostReceivePushWorker do
  let(:oldrev) { '123456' }
  let(:newrev) { '789012' }
  let(:ref) { 'refs/heads/tést' }
  let(:project) { create(:project, :repository) }
  let(:project_id) { project.id }
  let(:user_id) { project.owner.id }

  subject { described_class.new.perform(service_type, project_id, user_id, oldrev, newrev, ref) }

  shared_examples 'push services not called' do
    it do
      described_class::PUSH_SERVICES.each do |service|
        expect(service.constantize).not_to receive(:execute)
      end

      subject
    end
  end

  context 'when invalid param' do
    let(:service_type) { 'GitTagPushService' }

    context 'service_name' do
      let(:service_type) { 'InvalidServiceName' }

      it_behaves_like 'push services not called'
    end

    context 'project' do
      it_behaves_like 'push services not called'
    end

    context 'user' do
      it_behaves_like 'push services not called'
    end
  end

  context 'when valid params' do
    let(:service_object) { double }

    before do
      allow(service_object).to receive(:execute)
    end

    described_class::PUSH_SERVICES.each do |service|
      it 'calls the service' do
        expect(service.constantize)
          .to receive(:new)
                .with(project, project.owner, oldrev: oldrev, newrev: newrev, ref: ref)
                .and_return(service_object)

        expect(service_object).to receive(:execute)

        described_class.new.perform(service, project_id, user_id, oldrev, newrev, ref)
      end
    end
  end
end
