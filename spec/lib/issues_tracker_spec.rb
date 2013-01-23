require 'spec_helper'

describe IssuesTracker do
  let(:project) { double('project') }

  before do
    @project = project
    project.stub(repository: stub(ref_names: ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0']))
    project.stub(path_with_namespace: 'gitlab/gitlab-ci')
  end
  
  it 'returns url for issue' do
 ololo
  end
end
 
