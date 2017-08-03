require 'spec_helper'

describe Ci::PlayBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

  let(:service) do
    described_class.new(project, user)
  end

  context 'when project does not have repository yet' do
    let(:project) { create(:project) }

    it 'allows user to play build if protected branch rules are met' do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: build.ref, project: project)

      service.execute(build)

      expect(build.reload).to be_pending
    end

    it 'does not allow user with developer role to play build' do
      project.add_developer(user)

      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when project has repository' do
    let(:project) { create(:project, :repository) }

    it 'allows user with developer role to play a build' do
      project.add_developer(user)

      service.execute(build)

      expect(build.reload).to be_pending
    end
  end

  context 'when build is a playable manual action' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: build.ref, project: project)
    end

    it 'enqueues the build' do
      expect(service.execute(build)).to eq build
      expect(build.reload).to be_pending
    end

    it 'reassignes build user correctly' do
      service.execute(build)

      expect(build.reload.user).to eq user
    end
  end

  context 'when build is not a playable manual action' do
    let(:build) { create(:ci_build, when: :manual, pipeline: pipeline) }

    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: build.ref, project: project)
    end

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
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }

    it 'raises an error' do
      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when user does not have ability to trigger action' do
    before do
      create(:protected_branch, :no_one_can_push,
             name: build.ref, project: project)
    end

    it 'raises an error' do
      expect { service.execute(build) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end
end
