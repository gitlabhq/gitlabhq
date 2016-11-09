require 'spec_helper'

describe Ci::StopEnvironmentService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when environment exists' do
      before do
        create(:environment, :with_review_app, project: project)
      end

      it 'stops environment' do
        expect_any_instance_of(Environment).to receive(:stop!)

        service.execute('master')
      end
    end
  end
end
