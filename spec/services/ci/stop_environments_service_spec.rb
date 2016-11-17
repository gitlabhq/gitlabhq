require 'spec_helper'

describe Ci::StopEnvironmentsService, services: true do
  let(:project) { create(:project, :private) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when environment with review app exists' do
      before do
        create(:environment, :with_review_app, project: project,
                                               ref: 'feature')
      end

      context 'when user has permission to stop environment' do
        before do
          project.team << [user, :developer]
        end

        context 'when environment is associated with removed branch' do
          it 'stops environment' do
            expect_environment_stopped_on('feature')
          end
        end

        context 'when environment is associated with different branch' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('master')
          end
        end

        context 'when specified branch does not exist' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('non/existent/branch')
          end
        end

        context 'when no branch not specified' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on(nil)
          end
        end

        context 'when environment is not stoppable' do
          before do
            allow_any_instance_of(Environment)
              .to receive(:stoppable?).and_return(false)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('feature')
          end
        end
      end

      context 'when user does not have permission to stop environment' do
        before do
          project.team << [user, :guest]
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master')
        end
      end
    end

    context 'when there is no environment associated with review app' do
      before do
        create(:environment, project: project)
      end

      context 'when user has permission to stop environments' do
        before do
          project.team << [user, :master]
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master')
        end
      end
    end

    context 'when environment does not exist' do
      it 'does not raise error' do
        expect { service.execute('master') }
          .not_to raise_error
      end
    end
  end

  def expect_environment_stopped_on(branch)
    expect_any_instance_of(Environment)
      .to receive(:stop!)

    service.execute(branch)
  end

  def expect_environment_not_stopped_on(branch)
    expect_any_instance_of(Environment)
      .not_to receive(:stop!)

    service.execute(branch)
  end
end
