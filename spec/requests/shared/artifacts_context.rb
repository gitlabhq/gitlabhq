shared_context 'artifacts from ref and build name' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_pipeline,
            project: project,
            sha: project.commit('fix').sha,
            ref: 'fix')
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
      get path_from_ref(pipeline.ref, 'NOBUILD')
    end

    it('gives 404') { verify }
  end
end

shared_examples 'artifacts from ref successfully' do
  def create_new_pipeline(status)
    new_pipeline = create(:ci_pipeline, status: 'success')
    create(:ci_build, status, :artifacts, pipeline: new_pipeline)
  end

  context 'with sha' do
    before do
      get path_from_ref(pipeline.sha)
    end

    it('gives the file') { verify }
  end

  context 'with regular branch' do
    before do
      pipeline.update(ref: 'master',
                      sha: project.commit('master').sha)
    end

    before do
      get path_from_ref('master')
    end

    it('gives the file') { verify }
  end

  context 'with branch name containing slash' do
    before do
      pipeline.update(ref: 'improve/awesome',
                      sha: project.commit('improve/awesome').sha)
    end

    before do
      get path_from_ref('improve/awesome')
    end

    it('gives the file') { verify }
  end

  context 'with latest pipeline' do
    before do
      3.times do # creating some old pipelines
        create_new_pipeline(:success)
      end
    end

    before do
      get path_from_ref
    end

    it('gives the file') { verify }
  end

  context 'with success pipeline' do
    before do
      build # make sure pipeline was old, but still the latest success one
      create_new_pipeline(:pending)
    end

    before do
      get path_from_ref
    end

    it('gives the file') { verify }
  end
end
