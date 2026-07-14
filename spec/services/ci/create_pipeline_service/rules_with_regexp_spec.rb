# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- groups regexp rules tests separately from the larger rules_spec.rb
RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  # rubocop:enable RSpec/SpecFilePathFormat
  let(:user)        { project.first_owner }
  let(:ref)         { 'refs/heads/master' }
  let(:source)      { :push }
  let(:service)     { described_class.new(project, user, initialization_params) }
  let(:response)    { service.execute(source) }
  let(:pipeline)    { response.payload }
  let(:build_names) { pipeline.builds.pluck(:name) }

  let(:initialization_params) do
    { ref: ref, before: '00000000', after: project.commit(ref).sha, variables_attributes: nil }
  end

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  describe 'rules:changes:regexp' do
    let_it_be(:project, freeze: false) { create(:project, :repository) }

    let(:config) do
      <<-YAML
        regexp-job:
          script: echo regexp
          rules:
            - changes:
                regexp: '#{regexp}'

        control-job:
          script: echo control
      YAML
    end

    let(:changed_paths) do
      [instance_double(Gitlab::Git::ChangedPath, path: 'src/app.rb')]
    end

    before do
      allow_next_instance_of(Ci::Pipeline) do |pipeline|
        allow(pipeline).to receive(:changed_paths).and_return(changed_paths)
      end
    end

    context 'when a changed path matches' do
      let(:regexp) { '\Asrc/.*\.rb\z' }

      it 'includes the job' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('regexp-job', 'control-job')
      end
    end

    context 'when no changed path matches' do
      let(:regexp) { '\.go\z' }

      it 'excludes the job' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('control-job')
      end
    end

    context 'with a negative lookahead' do
      let(:regexp) { '\A(?!docs/)' }

      context 'when a non-docs file changed' do
        let(:changed_paths) { [instance_double(Gitlab::Git::ChangedPath, path: 'src/app.rb')] }

        it 'includes the job' do
          expect(build_names).to contain_exactly('regexp-job', 'control-job')
        end
      end

      context 'when only a docs file changed' do
        let(:changed_paths) { [instance_double(Gitlab::Git::ChangedPath, path: 'docs/index.md')] }

        it 'excludes the job' do
          expect(build_names).to contain_exactly('control-job')
        end
      end
    end

    context 'with variable expansion' do
      let(:config) do
        <<-YAML
          variables:
            SRC_DIR: src
          regexp-job:
            script: echo regexp
            rules:
              - changes:
                  regexp: '\\A$SRC_DIR/'
          control-job:
            script: echo control
        YAML
      end

      it 'expands the variable before matching and includes the job' do
        expect(build_names).to contain_exactly('regexp-job', 'control-job')
      end
    end

    context 'when the expanded pattern exceeds the length limit' do
      let(:config) do
        <<-YAML
          variables:
            HUGE: '#{'a' * 300}'
          regexp-job:
            script: echo regexp
            rules:
              - changes:
                  regexp: '\\A$HUGE/'
          control-job:
            script: echo control
        YAML
      end

      it 'fails the pipeline with a configuration error' do
        expect(pipeline.errors.full_messages).to contain_exactly(
          'Failed to parse rule for regexp-job: rules:changes:regexp is too long ' \
            '(maximum is 255 characters after variable expansion)'
        )
      end
    end

    context 'when a match exceeds the per-match timeout' do
      let(:regexp) { '\Asrc/a{1,30}{1,30}{1,30}b' }
      let(:changed_paths) do
        [instance_double(Gitlab::Git::ChangedPath, path: "src/#{'a' * 60}.rb")]
      end

      it 'fails the pipeline with a configuration error' do
        expect(pipeline.errors.full_messages).to contain_exactly(
          a_string_matching(/Failed to parse rule for regexp-job: rules:changes:regexp timed out/)
        )
      end
    end

    context 'when evaluation exceeds the total time budget' do
      let(:regexp) { '\Asrc/' }

      before do
        # Stub the matcher's clock so the deadline is set, then immediately exceeded
        # on the first per-path check. Scoped to the matcher to avoid affecting the
        # many other monotonic_time calls during pipeline creation.
        budget = Gitlab::Ci::Build::Rules::Rule::Clause::REGEXP_TOTAL_TIMEOUT_SECONDS
        allow_next_instance_of(Gitlab::Ci::Build::Rules::Rule::Clause::RegexpMatcher) do |matcher|
          allow(matcher).to receive(:current_monotonic_time).and_return(0, budget + 1)
        end
      end

      it 'fails the pipeline with a configuration error' do
        expect(pipeline.errors.full_messages).to contain_exactly(
          a_string_matching(/Failed to parse rule for regexp-job: rules:changes:regexp exceeded the time budget/)
        )
      end
    end

    context 'when the number of changed paths exceeds the comparison limit' do
      let(:regexp) { '\.go\z' }
      let(:changed_paths) do
        limit = Gitlab::Ci::Build::Rules::Rule::Clause::Changes::CHANGES_MAX_PATTERN_COMPARISONS
        Array.new(limit + 1) { |i| instance_double(Gitlab::Git::ChangedPath, path: "docs/file#{i}.md") }
      end

      it 'fails open and includes the job' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('regexp-job', 'control-job')
      end
    end
  end

  describe 'rules:exists:regexp' do
    let(:config) do
      <<-YAML
        regexp-job:
          script: echo regexp
          rules:
            - exists:
                regexp: '#{regexp}'

        control-job:
          script: echo control
      YAML
    end

    context 'when a file matches' do
      let_it_be(:project, freeze: false) { create(:project, :custom_repo, files: { 'spec/app_spec.rb' => '' }) }
      let(:regexp) { '_spec\.rb\z' }

      it 'includes the job' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('regexp-job', 'control-job')
      end
    end

    context 'when no file matches' do
      let_it_be(:project, freeze: false) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
      let(:regexp) { '\.go\z' }

      it 'excludes the job' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('control-job')
      end
    end

    context 'when the expanded pattern exceeds the length limit' do
      let_it_be(:project, freeze: false) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
      let(:config) do
        <<-YAML
          variables:
            HUGE: '#{'a' * 300}'
          regexp-job:
            script: echo regexp
            rules:
              - exists:
                  regexp: '\\A$HUGE/'
          control-job:
            script: echo control
        YAML
      end

      it 'fails the pipeline with a configuration error' do
        expect(pipeline.errors.full_messages).to contain_exactly(
          'Failed to parse rule for regexp-job: rules:exists:regexp is too long ' \
            '(maximum is 255 characters after variable expansion)'
        )
      end
    end
  end
end
