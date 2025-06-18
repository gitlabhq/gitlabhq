# frozen_string_literal: true

require 'spec_helper'

SLSA_PROVENANCE_V1_SCHEMA = 'app/validators/json_schemas/slsa/in_toto_v1/provenance_v1.json'

RSpec.describe Ci::Slsa::ProvenanceStatement, type: :model, feature_category: :continuous_integration do
  let(:parsed) { Gitlab::Json.parse(subject.to_json) }

  describe 'when ProvenanceStatement is correctly instantiated' do
    subject(:provenance_statement) { create(:provenance_statement) }

    it 'initializes without crashing' do
      expect(parsed['_type']).to eq('https://in-toto.io/Statement/v1')
      expect(parsed['predicateType']).to eq('https://slsa.dev/provenance/v1')
    end

    it 'has the correct subject' do
      subject = parsed['subject']

      expect(subject.length).to eq(2)
      expect(subject[0]['name']).to start_with('resource_')
      expect(subject[1]['name']).to start_with('resource_')
      expect(subject[0]['digest']['sha256'].length).to eq(64)
      expect(subject[1]['digest']['sha256'].length).to eq(64)
    end

    it 'has the correct predicate build definition' do
      build_definition = parsed['predicate']['buildDefinition']

      expect(build_definition['buildType']).to eq('https://gitlab.com/gitlab-org/gitlab-runner/-/blob/15/PROVENANCE.md')
      expect(build_definition['internalParameters']).to be_a(Hash)
      expect(build_definition['externalParameters']).to be_a(Hash)

      expect(build_definition['resolvedDependencies'].length).to eq(3)
    end

    it 'has the correct run details' do
      run_details = parsed['predicate']['runDetails']

      builder = run_details['builder']
      metadata = run_details['metadata']
      byproducts = run_details['byproducts']

      expect(builder['id']).to eq('https://gitlab.com/gitlab-org/gitlab-runner/-/blob/15/RUN_TYPE.md')
      expect(builder['version']['gitlab-runner']).to eq("4d7093e1")
      expect(builder['builderDependencies'].length).to eq(1)

      expect(metadata['invocationId']).to start_with('build_')
      expect(metadata['startedOn']).to eq('2025-06-09T08:48:14Z')
      expect(metadata['finishedOn']).to eq('2025-06-10T08:48:14Z')

      expect(byproducts.length).to eq(1)
    end

    describe 'and we check the schema' do
      let(:schema) do
        JSONSchemer.schema(Pathname.new(SLSA_PROVENANCE_V1_SCHEMA))
      end

      let(:errors) { schema.validate(parsed).map { |e| JSONSchemer::Errors.pretty(e) } }

      it 'conforms to specification' do
        expect(errors).to eq([])
      end
    end
  end

  describe '#from_build' do
    subject(:provenance_statement) { described_class.from_build(build) }

    let_it_be(:user) { create(:user) }
    let_it_be(:group, reload: true) { create_default(:group, :allow_runner_registration_token) }
    let_it_be(:project, reload: true) { create_default(:project, :repository, group: group) }

    let_it_be(:pipeline, reload: true) do
      create_default(
        :ci_pipeline,
        project: project,
        sha: project.commit.id,
        ref: project.default_branch,
        status: 'success'
      )
    end

    let_it_be(:runner) { create(:ci_runner, :hosted_runner) }
    let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner) }

    context 'when a valid build is passed as a parameter' do
      let_it_be(:build) { create(:ci_build, :artifacts, :finished, runner_manager: runner_manager, pipeline: pipeline) }

      it 'returns the appropriate JSON object' do
        expect(parsed['_type']).to eq('https://in-toto.io/Statement/v1')
        expect(parsed['predicateType']).to eq('https://slsa.dev/provenance/v1')
      end

      it 'has the correct subject' do
        subject = parsed['subject']

        expect(subject.length).to eq(1)
        expect(subject[0]['name']).to eq('ci_build_artifacts.zip')
        expect(subject[0]['digest']['sha256']).to eq('3d4a07bcbf2eaec380ad707451832924bee1197fbdf43d20d6d4bc96c8284268')
      end

      it 'has the correct predicate build definition' do
        build_definition = parsed['predicate']['buildDefinition']

        # TODO: update buildType as part of https://gitlab.com/gitlab-org/gitlab/-/issues/426764
        expect(build_definition['buildType']).to eq('https://gitlab.com/gitlab-org/gitlab/-/issues/546150')
        expect(build_definition['externalParameters']['variables']).to include("GITLAB_CI")
        expect(build_definition['internalParameters']['name']).to start_with("My runner")

        expect(build_definition['resolvedDependencies'].length).to eq(1)
      end

      it 'has the correct run details' do
        run_details = parsed['predicate']['runDetails']

        builder = run_details['builder']
        metadata = run_details['metadata']

        expect(builder['id']).to start_with('http://localhost/groups/GitLab-Admin-Bot/-/runners/')

        expect(metadata['invocationId']).to eq(build.id)
        expect(metadata['startedOn']).to eq(build.started_at.utc.try(:rfc3339))
        expect(metadata['finishedOn']).to eq(build.finished_at.utc.try(:rfc3339))
      end

      describe 'and we check the schema' do
        let(:schema) do
          JSONSchemer.schema(Pathname.new(SLSA_PROVENANCE_V1_SCHEMA))
        end

        let(:errors) { schema.validate(parsed).map { |e| JSONSchemer::Errors.pretty(e) } }

        it 'conforms to specification' do
          expect(errors).to eq([])
        end
      end
    end

    context 'when a build is invalid' do
      context 'when it does not have a build_runner_manager' do
        let_it_be(:build) { create(:ci_build, :artifacts, :finished, pipeline: pipeline) }

        it 'raises an exception' do
          expect { provenance_statement }.to raise_error(ArgumentError)
        end
      end

      context 'when artifact type is not specifically of "archive" file type' do
        let_it_be(:build) do
          create(:ci_build, :codequality_report, :finished, runner_manager: runner_manager, pipeline: pipeline)
        end

        it 'raises an exception' do
          expect { provenance_statement }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
