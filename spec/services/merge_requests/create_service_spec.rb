require 'spec_helper'

describe MergeRequests::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe :execute do
    context 'valid params' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master'
        }
      end
      let(:service) { MergeRequests::CreateService.new(project, user, opts) }

      before do
        project.team << [user, :master]
        allow(service).to receive(:execute_hooks)

        @merge_request = service.execute
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('Awesome merge_request') }

      it 'should execute hooks with default action' do
        expect(service).to have_received(:execute_hooks).with(@merge_request)
      end
    end
  end
end
