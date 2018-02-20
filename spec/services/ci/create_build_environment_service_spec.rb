require 'spec_helper'

describe Ci::CreateBuildEnvironmentService do
  let(:service) { described_class.new(project, user) }
  let(:job) { build(:ci_build, environment: environment_name) }
  let(:project) { job.pipeline.project }
  let(:user) { build(:user) }
  let(:environment_name) { 'the-environment-name' }

  describe '#execute' do
    it 'creates the environment' do
      service.execute(job)

      expect(project.environments.where(name: 'the-environment-name'))
        .not_to be_empty
    end

    context 'when the environment fails to be created' do
      let(:environment_name) { '/invalid-environment-name' }
      it 'raises ActiveRecord::RecordInvalid' do
        expect { service.execute(job) }
          .to raise_error(
            ActiveRecord::RecordInvalid,
            a_string_including("cannot start or end with '/'")
          )
      end
    end
  end
end
