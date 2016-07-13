shared_context 'artifacts from ref and build name' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit('fix').sha)
  end
  let(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    project.team << [user, :developer]
  end
end

shared_examples 'artifacts from ref with 404' do
  context 'has no such ref' do
    before do
      get path_from_ref('TAIL', build.name)
    end

    it('gives 404') { verify }
  end

  context 'has no such build' do
    before do
      get path_from_ref(pipeline.sha, 'NOBUILD')
    end

    it('gives 404') { verify }
  end
end

shared_examples 'artifacts from ref with 302' do
  context 'with sha' do
    before do
      get path_from_ref
    end

    it('redirects') { verify }
  end

  context 'with regular branch' do
    before do
      pipeline.update(sha: project.commit('master').sha)
    end

    before do
      get path_from_ref('master')
    end

    it('redirects') { verify }
  end

  context 'with branch name containing slash' do
    before do
      pipeline.update(sha: project.commit('improve/awesome').sha)
    end

    before do
      get path_from_ref('improve/awesome')
    end

    it('redirects') { verify }
  end

  context 'with latest build' do
    before do
      3.times do # creating some old builds
        create(:ci_build, :success, :artifacts, pipeline: pipeline)
      end
    end

    before do
      get path_from_ref
    end

    it('redirects') { verify }
  end

  context 'with success build' do
    before do
      build # make sure build was old, but still the latest success one
      create(:ci_build, :pending, :artifacts, pipeline: pipeline)
    end

    before do
      get path_from_ref
    end

    it('redirects') { verify }
  end
end
