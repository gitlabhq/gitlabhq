# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SanitizeAiCatalogItemDefinitions, migration: :gitlab_main, feature_category: :workflow_catalog do
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  # Definition contains invisible characters in the user_prompt field, making it unsafe.
  let(:unsafe_definition) do
    <<~DEFINITION
      {"tools": [], "user_prompt": "My user󠁈󠁩󠁤󠁤󠁥󠁮󠀠󠁣󠁨󠁡󠁲󠁳 prompt", "system_prompt": "My system prompt"}
    DEFINITION
  end

  let(:safe_definition) do
    <<~DEFINITION
      {"tools": [], "user_prompt": "My user prompt", "system_prompt": "My system prompt"}
    DEFINITION
  end

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let!(:project) do
    projects.create!(name: 'project', namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let!(:catalog_item) do
    ai_catalog_items.create!(
      name: 'Test Item',
      description: 'A test AI catalog item',
      public: true,
      project_id: project.id,
      organization_id: organization.id,
      item_type: 0
    )
  end

  let!(:unsafe_catalog_item_version) do
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: catalog_item.id,
      version: '1.0.0',
      definition: unsafe_definition,
      organization_id: organization.id,
      schema_version: 1
    )
  end

  let!(:safe_catalog_item_version) do
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: catalog_item.id,
      version: '1.1.0',
      definition: safe_definition,
      organization_id: organization.id,
      schema_version: 1
    )
  end

  it 'strips unsafe chars from item version definitions', :aggregate_failures do
    expect { migrate! }.to change {
      unsafe_catalog_item_version.reload.definition
    }.from(unsafe_definition).to(safe_definition)
  end

  it 'does not modify item version definitions that do not have unsafe chars', :aggregate_failures do
    expect { migrate! }.not_to change {
      safe_catalog_item_version.reload.definition
    }.from(safe_definition)
  end

  describe 'DANGEROUS_CHARS regex', feature_category: :workflow_catalog, migration: false do
    using RSpec::Parameterized::TableSyntax

    subject(:regex) { described_class::DANGEROUS_CHARS }

    describe 'detects dangerous characters' do
      where(:name, :input) do
        # Control characters (except tab, LF, CR)
        "null byte"                | "\u0000"
        "bell"                     | "\u0007"
        "backspace"                | "\u0008"
        "vertical tab"             | "\u000B"
        "form feed"                | "\u000C"
        "escape"                   | "\u001B"
        "delete"                   | "\u007F"

        # Soft hyphen
        "soft hyphen"              | "\u00AD"

        # Zero-width space
        "ZWSP"                     | "\u200B"

        # Bidi overrides
        "LRE"                      | "\u202A"
        "RLE"                      | "\u202B"
        "PDF"                      | "\u202C"
        "LRO"                      | "\u202D"
        "RLO"                      | "\u202E"

        # Word joiner
        "word joiner"              | "\u2060"

        # Bidi isolates
        "LRI"                      | "\u2066"
        "RLI"                      | "\u2067"
        "FSI"                      | "\u2068"
        "PDI"                      | "\u2069"

        # BOM
        "BOM"                      | "\uFEFF"

        # Annotations
        "annotation anchor"        | "\uFFF9"
        "annotation separator"     | "\uFFFA"
        "annotation terminator"    | "\uFFFB"

        # Object replacement
        "object replacement"       | "\uFFFC"

        # Invisible math operators
        "invisible times"          | "\u2062"
        "invisible separator"      | "\u2063"
        "invisible plus"           | "\u2064"

        # Tag characters
        "tag space"                | "\u{E0020}"
        "language tag"             | "\u{E0001}"
        "tag character A"          | "\u{E0041}"
        "end of tag range"         | "\u{E007F}"

        # Variation selectors supplement
        "VS17"                     | "\u{E0100}"
        "VS256"                    | "\u{E01EF}"
        "middle of VS supplement"  | "\u{E0150}"

        # Line/paragraph separators
        "line separator"           | "\u2028"
        "paragraph separator"      | "\u2029"
      end

      with_them do
        it "detects #{params[:name]}" do
          is_expected.to match(input)
        end
      end
    end

    describe 'allows safe characters' do
      where(:name, :input) do
        # Allowed control characters
        "tab"                      | "\t"
        "newline"                  | "\n"
        "carriage return"          | "\r"

        # Text (legitimate)
        "ASCII text"               | 'Hello, World!'
        "numbers"                  | '1234567890'
        "punctuation"              | '!@#$%^&*()'
        "hyphen (not soft)"        | 'well-known'
        "Arabic"                   | 'مرحبا'
        "Hebrew"                   | 'שלום'
        "Greek"                    | 'Γειά σου'
        "Emoji"                    | '👋🌍🎉'
      end

      with_them do
        it "allows #{params[:name]}" do
          is_expected.not_to match(input)
        end
      end
    end

    describe 'edge cases' do
      it 'detects dangerous chars embedded in normal text' do
        dangerous = "normal\u200Btext"
        expect(dangerous).to match(regex)
      end

      it 'detects multiple dangerous chars' do
        dangerous = "\u202Eevil\u202C"
        expect(dangerous).to match(regex)
      end

      it 'detects dangerous char at start of string' do
        dangerous = "\uFEFFtext"
        expect(dangerous).to match(regex)
      end

      it 'detects dangerous char at end of string' do
        dangerous = "text\u200B"
        expect(dangerous).to match(regex)
      end
    end
  end
end
