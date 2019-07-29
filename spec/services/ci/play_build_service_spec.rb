# frozen_string_literal: true

require 'spec_helper'

describe Ci::PlayBuildService, '#execute' do
  let(:user) { create(:user, developer_projects: [project]) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

  let(:service) do
    described_class.new(project, user)
  end

  context 'when project does not have repository yet' do
    let(:project) { create(:project) }

    it 'allows user to play build if protected branch rules are met' do
      create(:protected_branch, :developers_can_merge,
             name: build.ref, project: project)

      service.execute(build)

      expect(build.reload).to be_pending
    end

    it 'does not allow user with developer role to play build' do
      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when project has repository' do
    let(:project) { create(:project, :repository) }

    it 'allows user with developer role to play a build' do
      service.execute(build)

      expect(build.reload).to be_pending
    end

    it 'prevents a blocked developer from playing a build' do
      user.block!

      expect { service.execute(build) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when build is a playable manual action' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'enqueues the build' do
      expect(service.execute(build)).to eq build
      expect(build.reload).to be_pending
    end

    it 'reassignes build user correctly' do
      service.execute(build)

      expect(build.reload.user).to eq user
    end

    context 'when variables are supplied' do
      let(:job_variables) do
        [{ key: 'first', secret_value: 'first' },
         { key: 'second', secret_value: 'second' }]
      end

      it 'assigns the variables to the build' do
        service.execute(build, job_variables)

        expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
      end
    end
  end

  context 'when build is not a playable manual action' do
    let(:build) { create(:ci_build, when: :manual, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'duplicates the build' do
      duplicate = service.execute(build)

      expect(duplicate).not_to eq build
      expect(duplicate).to be_pending
    end

    it 'assigns users correctly' do
      duplicate = service.execute(build)

      expect(build.user).not_to eq user
      expect(duplicate.user).to eq user
    end
  end

  context 'when build is not action' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }

    it 'raises an error' do
      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when user does not have ability to trigger action' do
    let(:user) { create(:user) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'raises an error' do
      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end
end
