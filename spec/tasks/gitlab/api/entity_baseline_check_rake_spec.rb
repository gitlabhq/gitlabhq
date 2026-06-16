# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:api:check_high_impact_entity_baseline rake task', :silence_output, feature_category: :api do
  let(:baseline_path) { Rails.root.join('rubocop/cop/api/config/api_entity_exposure_baseline.yml') }
  let(:baseline) { YAML.load_file(baseline_path) || {} }

  before do
    Rake.application.rake_require 'tasks/gitlab/api/entity_baseline_check'
  end

  def stub_high_impact(results)
    analyzer = instance_double(Gitlab::RestApi::EntityUsageRadiusAnalyzer, high_impact_entities: results)
    allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer).to receive(:new).and_return(analyzer)
  end

  context 'when all high-impact entities are already in the baseline' do
    let(:existing_path) { baseline.each_key.first }
    let(:entity_class) { stub_const('API::Entities::Existing', Class.new(Grape::Entity)) }

    let(:expected_output) do
      <<~OUTPUT
        No new high-impact entities detected. Baseline is up to date.
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_class).and_return(existing_path)
      stub_high_impact({ entity_class => 20 })
    end

    it 'prints exactly the up-to-date message' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to output(expected_output).to_stdout
    end

    it 'does not raise' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }.not_to raise_error
    end

    it 'does not write to the baseline file' do
      expect(File).not_to receive(:write)

      run_rake_task('gitlab:api:check_high_impact_entity_baseline')
    end
  end

  context 'when a high-impact entity is missing from the baseline' do
    let(:new_path) { 'lib/api/entities/new_thing.rb' }
    let(:entity_class) { double('entity_class', name: 'API::Entities::NewThing') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class

    let(:expected_output) do
      <<~OUTPUT
        ========================================================================
        NEW HIGH-IMPACT API ENTITIES DETECTED
        ========================================================================

          Entity:       API::Entities::NewThing
          File:         lib/api/entities/new_thing.rb
          Usage radius: 25 endpoints
          Exposed:      2 field(s)

        ========================================================================
        Add the following to:
          rubocop/cop/api/config/api_entity_exposure_baseline.yml
        ========================================================================
        lib/api/entities/new_thing.rb:
        - id
        - name
        Documentation: https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_class).and_return(new_path)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(new_path).and_return(%w[id name])
      stub_high_impact({ entity_class => 25 })
    end

    it 'prints exactly the drift report with listing, YAML snippet, and docs link' do
      expect do
        run_rake_task('gitlab:api:check_high_impact_entity_baseline')
      rescue SystemExit
        # expected
      end.to output(expected_output).to_stdout
    end

    it 'aborts with non-zero exit' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end

    it 'does not write to the baseline file' do
      expect(File).not_to receive(:write)

      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end
  end

  context 'when entity_file_path returns nil for a high-impact entity' do
    let(:entity_class) { double('entity_class', name: 'API::Entities::Anonymous') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class

    let(:expected_output) do
      <<~OUTPUT
        No new high-impact entities detected. Baseline is up to date.
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_class).and_return(nil)
      stub_high_impact({ entity_class => 30 })
    end

    it 'skips the entity and prints exactly the up-to-date message' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to output(expected_output).to_stdout
    end

    it 'does not abort' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }.not_to raise_error
    end
  end

  context 'when multiple high-impact entities are missing from the baseline' do
    let(:path_a) { 'lib/api/entities/new_a.rb' }
    let(:path_b) { 'lib/api/entities/new_b.rb' }
    let(:entity_a) { double('entity_a', name: 'API::Entities::NewA') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class
    let(:entity_b) { double('entity_b', name: 'API::Entities::NewB') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class

    let(:expected_output) do
      <<~OUTPUT
        ========================================================================
        NEW HIGH-IMPACT API ENTITIES DETECTED
        ========================================================================

          Entity:       API::Entities::NewA
          File:         lib/api/entities/new_a.rb
          Usage radius: 20 endpoints
          Exposed:      2 field(s)

          Entity:       API::Entities::NewB
          File:         lib/api/entities/new_b.rb
          Usage radius: 30 endpoints
          Exposed:      2 field(s)

        ========================================================================
        Add the following to:
          rubocop/cop/api/config/api_entity_exposure_baseline.yml
        ========================================================================
        lib/api/entities/new_a.rb:
        - id
        - name
        lib/api/entities/new_b.rb:
        - bar
        - foo
        Documentation: https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_a).and_return(path_a)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_b).and_return(path_b)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(path_a).and_return(%w[id name])
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(path_b).and_return(%w[foo bar])
      stub_high_impact({ entity_a => 20, entity_b => 30 })
    end

    it 'prints exactly the drift report listing both entities and their YAML snippets' do
      expect do
        run_rake_task('gitlab:api:check_high_impact_entity_baseline')
      rescue SystemExit
        # expected
      end.to output(expected_output).to_stdout
    end

    it 'aborts the task' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end
  end

  context 'when a high-impact entity exposes no extractable fields' do
    let(:dynamic_path) { 'lib/api/entities/dynamic_thing.rb' }
    let(:entity_class) { double('entity_class', name: 'API::Entities::DynamicThing') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class

    let(:expected_output) do
      <<~OUTPUT
        ========================================================================
        NEW HIGH-IMPACT API ENTITIES DETECTED
        ========================================================================

          Entity:       API::Entities::DynamicThing
          File:         lib/api/entities/dynamic_thing.rb
          Usage radius: 22 endpoints
          Exposed:      0 field(s)

        ========================================================================
        MANUAL REVIEW REQUIRED: no exposed fields could be extracted
        ========================================================================
        These entities expose fields dynamically or via macros/EE overrides that
        cannot be parsed automatically. Check the elements yourself and add them
        to the YAML manually:
          lib/api/entities/dynamic_thing.rb (API::Entities::DynamicThing)

        Documentation: https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_class).and_return(dynamic_path)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(dynamic_path).and_return([])
      stub_high_impact({ entity_class => 22 })
    end

    it 'lists the entity under manual review instead of emitting a YAML snippet' do
      expect do
        run_rake_task('gitlab:api:check_high_impact_entity_baseline')
      rescue SystemExit
        # expected
      end.to output(expected_output).to_stdout
    end

    it 'does not write to the baseline file' do
      expect(File).not_to receive(:write)

      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end

    it 'aborts the task' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end
  end

  context 'when high-impact entities mix extractable and non-extractable fields' do
    let(:path_a) { 'lib/api/entities/new_a.rb' }
    let(:path_b) { 'lib/api/entities/new_b.rb' }
    let(:entity_a) { double('entity_a', name: 'API::Entities::NewA') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class
    let(:entity_b) { double('entity_b', name: 'API::Entities::NewB') } # rubocop:disable RSpec/VerifiedDoubles -- dynamic entity class

    let(:expected_output) do
      <<~OUTPUT
        ========================================================================
        NEW HIGH-IMPACT API ENTITIES DETECTED
        ========================================================================

          Entity:       API::Entities::NewA
          File:         lib/api/entities/new_a.rb
          Usage radius: 20 endpoints
          Exposed:      2 field(s)

          Entity:       API::Entities::NewB
          File:         lib/api/entities/new_b.rb
          Usage radius: 30 endpoints
          Exposed:      0 field(s)

        ========================================================================
        Add the following to:
          rubocop/cop/api/config/api_entity_exposure_baseline.yml
        ========================================================================
        lib/api/entities/new_a.rb:
        - id
        - name

        ========================================================================
        MANUAL REVIEW REQUIRED: no exposed fields could be extracted
        ========================================================================
        These entities expose fields dynamically or via macros/EE overrides that
        cannot be parsed automatically. Check the elements yourself and add them
        to the YAML manually:
          lib/api/entities/new_b.rb (API::Entities::NewB)

        Documentation: https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities
      OUTPUT
    end

    before do
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_a).and_return(path_a)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:entity_file_path).with(entity_b).and_return(path_b)
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(path_a).and_return(%w[id name])
      allow(Gitlab::RestApi::EntityUsageRadiusAnalyzer)
        .to receive(:extract_field_names).with(path_b).and_return([])
      stub_high_impact({ entity_a => 20, entity_b => 30 })
    end

    it 'emits a snippet for the extractable entity and lists the other for manual review' do
      expect do
        run_rake_task('gitlab:api:check_high_impact_entity_baseline')
      rescue SystemExit
        # expected
      end.to output(expected_output).to_stdout
    end

    it 'aborts the task' do
      expect { run_rake_task('gitlab:api:check_high_impact_entity_baseline') }
        .to raise_error(SystemExit)
    end
  end
end
