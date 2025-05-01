# frozen_string_literal: true

require 'spec_helper'

# These shared_contexts and shared_examples are used to test the # CI/CD templates
# powering the Application Security Testing (AST) features.
# There is a lot of repitition across these templates and the setup for these
# specs is expensive.
#
# Usually, each template will have its behavior tested in these 3 different pipelines types:
# - default branch pipeline
# - feature branch pipeline
# - MR pipeline
#
# Additionally, some templates have CI jobs using rules:exists which involves setting up
# a project with a repository that contains specific files. To improve speed and
# efficiency, the setup steps are extracted into shared_context that use let_it_be and
# before(:context). This ensures to create the project only once per scenario.
# Though these contexts assume a particular usage which reduces flexibility.
# Please check existing specs for examples.

RSpec.shared_context "when project has files" do |files|
  let_it_be(:files_for_repo) { files.index_with('') }
  let_it_be(:project) { create(:project, :custom_repo, files: files_for_repo) }
  let_it_be(:user) { project.first_owner }
end

RSpec.shared_context 'with CI variables' do |variables|
  before do
    variables.each do |(key, value)|
      create(:ci_variable, project: project, key: key, value: value)
    end
  end
end

RSpec.shared_context 'with default branch pipeline setup' do
  let_it_be(:pipeline_branch) { default_branch }
  let_it_be(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
end

RSpec.shared_context 'with feature branch pipeline setup' do
  let_it_be(:pipeline_branch) { feature_branch }
  let_it_be(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }

  before(:context) do
    project.repository.create_file(
      project.creator,
      'branch.patch',
      '',
      message: "Add file to feature branch",
      branch_name: pipeline_branch,
      # Ensure new branch includes expected project files from default branch.
      start_branch_name: default_branch)
  end
end

RSpec.shared_context 'with MR pipeline setup' do
  let_it_be(:pipeline_branch) { 'mr_branch' }
  let_it_be(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }

  let(:pipeline) { service.execute(merge_request).payload }

  let_it_be(:merge_request) do
    # Ensure MR has at least one commit otherwise MR pipeline won't be triggered.
    # This also seems to be required to happen before the MR creation.
    project.repository.create_file(
      project.creator,
      'MR.patch',
      '',
      message: "Add patch to MR branch",
      branch_name: pipeline_branch,
      # Ensure new branch includes expected project files from default branch.
      start_branch_name: default_branch)

    create(:merge_request,
      source_project: project,
      source_branch: pipeline_branch,
      target_project: project,
      target_branch: default_branch)
  end
end

RSpec.shared_examples 'missing stage' do |stage_name|
  it "fails due to missing '#{stage_name}' stage" do
    expect(pipeline.builds.pluck(:name)).to be_empty
    expect(pipeline.errors.full_messages.first).to match(
      /job: chosen stage #{stage_name} does not exist; available stages are/
    )
  end
end

RSpec.shared_examples 'has expected jobs' do |jobs|
  it 'includes jobs', if: jobs.any? do
    expect(pipeline.builds.pluck(:name)).to match_array(jobs)
    # TODO:  Failing for DAST related templates with error:
    # "Insufficient permissions for dast_configuration keyword"
    #  expect(pipeline.errors.full_messages).to be_empty unless ignore_errors
  end

  it 'includes no jobs', if: jobs.empty? do
    expect(pipeline.builds.pluck(:name)).to be_empty
    expect(pipeline.errors.full_messages).to match_array(
      [sanitize_message(Ci::Pipeline.rules_failure_message)])
  end
end

RSpec.shared_examples 'has expected image tag' do |tag, jobs|
  jobs.each do |job|
    it "uses image tag #{tag} for job #{job}" do
      build = pipeline.builds.find_by(name: job)
      image_tag = expand_job_image(build).rpartition(':').last
      expect(image_tag).to eql(tag)
    end
  end
end

RSpec.shared_examples 'uses SECURE_ANALYZERS_PREFIX' do |jobs|
  context 'when SECURE_ANALYZERS_PREFIX is set', fips_mode: false do
    include_context 'with CI variables', { 'SECURE_ANALYZERS_PREFIX' => 'my.custom-registry' }

    jobs.each do |job|
      it "uses SECURE_ANALYZERS_PREFIX for the image of job #{job}" do
        build = pipeline.builds.find_by(name: job)
        image_without_tag = expand_job_image(build).rpartition(':').first
        expect(image_without_tag).to start_with('my.custom-registry')
      end
    end
  end
end

RSpec.shared_examples 'has FIPS compatible jobs' do |variable, jobs|
  context 'when CI_GITLAB_FIPS_MODE=false', fips_mode: false do
    jobs.each do |job|
      it "sets #{variable} to '' for job #{job}" do
        build = pipeline.builds.find_by(name: job)
        expect(String(build.variables.to_hash[variable])).to eql('')
      end
    end
  end

  context 'when CI_GITLAB_FIPS_MODE=true', :fips_mode do
    jobs.each do |job|
      it "sets #{variable} to '-fips' for job #{job}" do
        build = pipeline.builds.find_by(name: job)
        expect(String(build.variables.to_hash[variable])).to eql('-fips')
      end
    end
  end
end

RSpec.shared_examples 'has jobs that can be disabled' do |key, disabled_values, jobs|
  disabled_values.each do |disabled_value|
    context "when #{key} is set to '#{disabled_value}'" do
      before do
        create(:ci_variable, project: project, key: key, value: disabled_value)
      end

      include_examples 'has expected jobs', []
    end
  end

  # This ensures we don't accidentally disable jobs when user sets the variable to 'false'.
  context "when #{key} is set to 'false'" do
    before do
      create(:ci_variable, project: project, key: key, value: 'false')
    end

    include_examples 'has expected jobs', jobs
  end
end

# TODO: remove (need to update all templates)
RSpec.shared_examples 'acts as branch pipeline' do |jobs|
  context 'when branch pipeline' do
    let(:pipeline_branch) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }

    it 'includes a job' do
      expect(pipeline.builds.pluck(:name)).to match_array(jobs)
    end
  end
end

def expand_job_image(build)
  variables = build.variables.sort_and_expand_all
  ExpandVariables.expand(build.image.name, variables)
end
