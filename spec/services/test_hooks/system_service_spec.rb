require 'spec_helper'

describe TestHooks::SystemService do
  let(:current_user) { create(:user) }

  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:hook)    { create(:system_hook) }
    let(:service) { described_class.new(hook, current_user, trigger) }
    let(:sample_data) { { data: 'sample' }}
    let(:success_result) { { status: :success, http_status: 200, message: 'ok' } }

    before do
      allow(Project).to receive(:first).and_return(project)
    end

    context 'hook with not implemented test' do
      let(:trigger) { 'not_implemented_events' }

      it 'returns error message' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Testing not available for this hook' })
      end
    end

    context 'push_events' do
      let(:trigger) { 'push_events' }

      it 'returns error message if not enough data' do
        allow(project).to receive(:empty_repo?).and_return(true)

        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: "Ensure project \"#{project.human_name}\" has commits." })
      end

      it 'executes hook' do
        allow(project).to receive(:empty_repo?).and_return(false)
        allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'tag_push_events' do
      let(:trigger) { 'tag_push_events' }

      it 'returns error message if not enough data' do
        allow(project.repository).to receive(:tags).and_return([])

        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: "Ensure project \"#{project.human_name}\" has tags." })
      end

      it 'executes hook' do
        allow(project.repository).to receive(:tags).and_return(['tag'])
        allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'repository_update_events' do
      let(:trigger) { 'repository_update_events' }

      it 'returns error message if not enough data' do
        allow(project).to receive(:commit).and_return(nil)
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: "Ensure project \"#{project.human_name}\" has commits." })
      end

      it 'executes hook' do
        allow(project).to receive(:empty_repo?).and_return(false)
        allow(Gitlab::DataBuilder::Repository).to receive(:update).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end
  end
end
