require 'spec_helper'

describe Ci::StopEnvironmentsService do
  let(:project) { create(:project, :private, :repository) }
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
          project.add_developer(user)
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

        context 'when environment is not stopped' do
          before do
            allow_any_instance_of(Environment)
              .to receive(:state).and_return(:stopped)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('feature')
          end
        end
      end

      context 'when user does not have permission to stop environment' do
        context 'when user has no access to manage deployments' do
          before do
            project.add_guest(user)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('master')
          end
        end
      end

      context 'when branch for stop action is protected' do
        before do
          project.add_developer(user)
          create(:protected_branch, :no_one_can_push,
                 name: 'master', project: project)
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
          project.add_master(user)
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
