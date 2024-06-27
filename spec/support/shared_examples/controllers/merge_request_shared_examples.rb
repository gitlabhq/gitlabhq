# frozen_string_literal: true

RSpec.shared_examples 'api merge with auto merge' do
  it 'returns the correct auto merge strategy' do
    set_auto_merge

    expect(json_response).to eq('status' => status)
  end

  it 'sets the MR to merge when the pipeline succeeds' do
    expect_next_instance_of(service_class) do |service|
      expect(service).to receive(:execute).with(merge_request)
      allow(service).to receive(:available_for?).and_return(true)
    end

    set_auto_merge
  end

  context 'for logging' do
    let(:expected_params) { { merge_action_status: status } }
    let(:subject_proc) { proc { subject } }

    subject { set_auto_merge }

    it_behaves_like 'storing arguments in the application context'
    it_behaves_like 'not executing any extra queries for the application context'
  end

  context 'when project.only_allow_merge_if_pipeline_succeeds? is true' do
    before do
      project.update_column(:only_allow_merge_if_pipeline_succeeds, true)
    end

    context 'and head pipeline is not the current one' do
      before do
        head_pipeline.update!(sha: 'not_current_sha')
      end

      it 'returns expected status when pipeline is not current' do
        set_auto_merge

        expect(json_response).to eq('status' => not_current_pipeline_status)
      end
    end

    it 'returns the correct auto merge strategy' do
      set_auto_merge

      expect(json_response).to eq('status' => status)
    end
  end

  context 'when auto merge has not been enabled yet' do
    it 'calls AutoMergeService#execute' do
      expect_next_instance_of(AutoMergeService) do |service|
        expect(service).to receive(:execute).with(merge_request, status)
      end

      set_auto_merge
    end
  end

  context 'when auto merge has already been enabled' do
    before do
      merge_request.update!(auto_merge_enabled: true, merge_user: user)
    end

    it 'calls AutoMergeService#update' do
      expect_next_instance_of(AutoMergeService) do |service|
        expect(service).to receive(:update).with(merge_request)
      end

      set_auto_merge
    end
  end
end
