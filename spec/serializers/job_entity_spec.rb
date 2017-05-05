require 'spec_helper'

describe JobEntity do
  let(:user) { create(:user) }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:user).and_return(user)
  end

  let(:entity) do
    described_class.new(job, request: request)
  end

  describe '#as_json' do
    let(:job) { create(:ci_build) }

    subject { entity.as_json }

    it 'contains the name and status fields' do
      expect(subject).to include :name, :status
    end

    it 'contains detailed status' do
      expect(subject[:status]).to include :text, :label, :group, :icon
      expect(subject[:status][:label]).to eq 'pending'
    end

    it 'contains valid name' do
      expect(subject[:name]).to eq 'test'
    end
  end
end
