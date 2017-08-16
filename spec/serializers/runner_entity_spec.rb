require 'spec_helper'

describe RunnerEntity do
  let(:runner) { create(:ci_runner, :specific) }
  let(:entity) { described_class.new(runner, request: request, current_user: user) }
  let(:request) { double('request') }
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:id, :description)
      expect(subject).to include(:edit_path)
    end
  end
end
