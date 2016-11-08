require 'spec_helper'

describe Ci::StopEnvironmentService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when environment exists' do
      let(:environment) { create(:environment, project: project) }
      let(:deployable) { create(:ci_build) }

      let(:stop_build) do
        create(:ci_build, :manual, name: 'environment/teardown',
                                   pipeline: deployable.pipeline)
      end

      before do
        create(:deployment, environment: environment,
                            deployable: deployable,
                            on_stop: stop_build.name,
                            user: user,
                            project: project,
                            sha: project.commit.id)
      end

      it 'stops environment' do
        expect_any_instance_of(Environment).to receive(:stop!)

        service.execute('master')
      end
    end
  end
end
