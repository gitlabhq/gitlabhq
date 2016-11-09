require 'spec_helper'

describe Ci::StopEnvironmentService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when environment with review app exists' do
      before do
        create(:environment, :with_review_app, project: project)
      end

      it 'stops environment' do
        expect_any_instance_of(Environment).to receive(:stop!)

        service.execute('master')
      end

      context 'when specified branch does not exist' do
        it 'does not stop environment' do
          expect_any_instance_of(Environment).not_to receive(:stop!)

          service.execute('non/existent/branch')
        end
      end

      context 'when no branch not specified' do
        it 'does not stop environment' do
          expect_any_instance_of(Environment).not_to receive(:stop!)

          service.execute(nil)
        end
      end

      context 'when environment is not stoppable' do
        before do
          allow_any_instance_of(Environment)
            .to receive(:stoppable?).and_return(false)
        end

        it 'does not stop environment' do
          expect_any_instance_of(Environment).not_to receive(:stop!)

          service.execute('master')
        end
      end
    end

    context 'when there is no environment associated with review app' do
      before do
        create(:environment, project: project)
      end

      it 'does not stop environment' do
        expect_any_instance_of(Environment).not_to receive(:stop!)

        service.execute('master')
      end
    end

    context 'when environment does not exist' do
      it 'does not raise error' do
        expect { service.execute('master') }
          .not_to raise_error
      end
    end
  end
end
