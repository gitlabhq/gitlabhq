# frozen_string_literal: true

RSpec.shared_examples 'job_execution_status field' do |resource_type|
  let(:entity_key) { :"#{resource_type}_entity" }

  describe 'for job_execution_status field' do
    context "when #{resource_type} has no executing builds" do
      it 'returns :idle' do
        expect(send(entity_key)[:job_execution_status]).to eq(:idle)
      end
    end

    context "when #{resource_type} has executing builds" do
      before do
        create(:ci_build, :running, resource_type => send(resource_type))
      end

      it 'returns :active' do
        expect(send(entity_key)[:job_execution_status]).to eq(:active)
      end
    end

    context "when #{resource_type} does not exist" do
      let(resource_type) { nil }

      it 'returns nil and does not call lazy_job_execution_status' do
        expect(entity).not_to receive(:lazy_job_execution_status)
        expect(send(entity_key)).to be_nil
      end
    end
  end
end
