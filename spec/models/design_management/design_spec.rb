# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::Design do
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:design1) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:design2) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:design3) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:deleted_design) { create(:design, :with_versions, deleted: true) }

  describe 'relations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_many(:actions) }
    it { is_expected.to have_many(:versions) }
    it { is_expected.to have_many(:notes).dependent(:delete_all) }
    it { is_expected.to have_many(:user_mentions) }
  end

  describe 'validations' do
    subject(:design) { build(:design) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_uniqueness_of(:filename).scoped_to(:issue_id) }

    it "validates that the extension is an image" do
      design.filename = "thing.txt"
      extensions = described_class::SAFE_IMAGE_EXT + described_class::DANGEROUS_IMAGE_EXT

      expect(design).not_to be_valid
      expect(design.errors[:filename].first).to eq(
        "does not have a supported extension. Only #{extensions.to_sentence} are supported"
      )
    end

    describe 'validating files with .svg extension' do
      before do
        design.filename = "thing.svg"
      end

      it "allows .svg files when feature flag is enabled" do
        stub_feature_flags(design_management_allow_dangerous_images: true)

        expect(design).to be_valid
      end

      it "does not allow .svg files when feature flag is disabled" do
        stub_feature_flags(design_management_allow_dangerous_images: false)

        expect(design).not_to be_valid
        expect(design.errors[:filename].first).to eq(
          "does not have a supported extension. Only #{described_class::SAFE_IMAGE_EXT.to_sentence} are supported"
        )
      end
    end
  end

  describe 'scopes' do
    describe '.visible_at_version' do
      let(:versions) { DesignManagement::Version.where(issue: issue).ordered }
      let(:found) { described_class.visible_at_version(version) }

      context 'at oldest version' do
        let(:version) { versions.last }

        it 'finds the first design only' do
          expect(found).to contain_exactly(design1)
        end
      end

      context 'at version 2' do
        let(:version) { versions.second }

        it 'finds the first and second designs' do
          expect(found).to contain_exactly(design1, design2)
        end
      end

      context 'at latest version' do
        let(:version) { versions.first }

        it 'finds designs' do
          expect(found).to contain_exactly(design1, design2, design3)
        end
      end

      context 'when the argument is nil' do
        let(:version) { nil }

        it 'finds all undeleted designs' do
          expect(found).to contain_exactly(design1, design2, design3)
        end
      end

      describe 'one of the designs was deleted before the given version' do
        before do
          delete_designs(design2)
        end

        it 'is not returned' do
          current_version = versions.first

          expect(described_class.visible_at_version(current_version)).to contain_exactly(design1, design3)
        end
      end

      context 'a re-created history' do
        before do
          delete_designs(design1, design2)
          restore_designs(design1)
        end

        it 'is returned, though other deleted events are not' do
          expect(described_class.visible_at_version(nil)).to contain_exactly(design1, design3)
        end
      end

      # test that a design that has been modified at various points
      # can be queried for correctly at different points in its history
      describe 'dead or alive' do
        let(:versions) { DesignManagement::Version.where(issue: issue).map { |v| [v, :alive] } }

        before do
          versions << [delete_designs(design1),          :dead]
          versions << [modify_designs(design2),          :dead]
          versions << [restore_designs(design1),         :alive]
          versions << [modify_designs(design3),          :alive]
          versions << [delete_designs(design1),          :dead]
          versions << [modify_designs(design2, design3), :dead]
          versions << [restore_designs(design1),         :alive]
        end

        it 'can establish the history at any point' do
          history = versions.map(&:first).map do |v|
            described_class.visible_at_version(v).include?(design1) ? :alive : :dead
          end

          expect(history).to eq(versions.map(&:second))
        end
      end
    end

    describe '.with_filename' do
      it 'returns correct design when passed a single filename' do
        expect(described_class.with_filename(design1.filename)).to eq([design1])
      end

      it 'returns correct designs when passed an Array of filenames' do
        expect(
          described_class.with_filename([design1, design2].map(&:filename))
        ).to contain_exactly(design1, design2)
      end
    end

    describe '.on_issue' do
      it 'returns correct designs when passed a single issue' do
        expect(described_class.on_issue(issue)).to match_array(issue.designs)
      end

      it 'returns correct designs when passed an Array of issues' do
        expect(
          described_class.on_issue([issue, deleted_design.issue])
        ).to contain_exactly(design1, design2, design3, deleted_design)
      end
    end

    describe '.current' do
      it 'returns just the undeleted designs' do
        delete_designs(design3)

        expect(described_class.current).to contain_exactly(design1, design2)
      end
    end
  end

  describe '#visible_in?' do
    let_it_be(:issue) { create(:issue) }

    # It is expensive to re-create complex histories, so we do it once, and then
    # assert that we can establish visibility at any given version.
    it 'tells us when a design is visible' do
      expected = []

      first_design = create(:design, :with_versions, issue: issue, versions_count: 1)
      prior_to_creation = first_design.versions.first
      expected << [prior_to_creation, :not_created_yet, false]

      v = modify_designs(first_design)
      expected << [v, :not_created_yet, false]

      design = create(:design, :with_versions, issue: issue, versions_count: 1)
      created_in = design.versions.first
      expected << [created_in, :created, true]

      # The future state should not affect the result for any state, so we
      # ensure that most states have a long future as well as a rich past
      2.times do
        v = modify_designs(first_design)
        expected << [v, :unaffected_visible, true]

        v = modify_designs(design)
        expected << [v, :modified, true]

        v = modify_designs(first_design)
        expected << [v, :unaffected_visible, true]

        v = delete_designs(design)
        expected << [v, :deleted, false]

        v = modify_designs(first_design)
        expected << [v, :unaffected_nv, false]

        v = restore_designs(design)
        expected << [v, :restored, true]
      end

      delete_designs(design) # ensure visibility is not corelated with current state

      got = expected.map do |(v, sym, _)|
        [v, sym, design.visible_in?(v)]
      end

      expect(got).to eq(expected)
    end
  end

  describe '#to_ability_name' do
    it { expect(described_class.new.to_ability_name).to eq('design') }
  end

  describe '#status' do
    context 'the design is new' do
      subject { build(:design) }

      it { is_expected.to have_attributes(status: :new) }
    end

    context 'the design is current' do
      subject { design1 }

      it { is_expected.to have_attributes(status: :current) }
    end

    context 'the design has been deleted' do
      subject { deleted_design }

      it { is_expected.to have_attributes(status: :deleted) }
    end
  end

  describe '#deleted?' do
    context 'the design is new' do
      let(:design) { build(:design) }

      it 'is falsy' do
        expect(design).not_to be_deleted
      end
    end

    context 'the design is current' do
      let(:design) { design1 }

      it 'is falsy' do
        expect(design).not_to be_deleted
      end
    end

    context 'the design has been deleted' do
      let(:design) { deleted_design }

      it 'is truthy' do
        expect(design).to be_deleted
      end
    end

    context 'the design has been deleted, but was then re-created' do
      let(:design) { create(:design, :with_versions, versions_count: 1, deleted: true) }

      it 'is falsy' do
        restore_designs(design)

        expect(design).not_to be_deleted
      end
    end
  end

  describe "#new_design?" do
    let(:design) { design1 }

    it "is false when there are versions" do
      expect(design1).not_to be_new_design
    end

    it "is true when there are no versions" do
      expect(build(:design)).to be_new_design
    end

    it 'is false for deleted designs' do
      expect(deleted_design).not_to be_new_design
    end

    it "does not cause extra queries when actions are loaded" do
      design.actions.map(&:id)

      expect { design.new_design? }.not_to exceed_query_limit(0)
    end

    it "implicitly caches values" do
      expect do
        design.new_design?
        design.new_design?
      end.not_to exceed_query_limit(1)
    end

    it "queries again when the clear_version_cache trigger has been called" do
      expect do
        design.new_design?
        design.clear_version_cache
        design.new_design?
      end.not_to exceed_query_limit(2)
    end

    it "causes a single query when there versions are not loaded" do
      design.reload

      expect { design.new_design? }.not_to exceed_query_limit(1)
    end
  end

  describe "#full_path" do
    it "builds the full path for a design" do
      design = build(:design, filename: "hello.jpg")
      expected_path = "#{DesignManagement.designs_directory}/issue-#{design.issue.iid}/hello.jpg"

      expect(design.full_path).to eq(expected_path)
    end
  end

  describe '#diff_refs' do
    let(:design) { create(:design, :with_file, versions_count: versions_count) }

    context 'there are several versions' do
      let(:versions_count) { 3 }

      it "builds diff refs based on the first commit and it's for the design" do
        expect(design.diff_refs.base_sha).to eq(design.versions.ordered.second.sha)
        expect(design.diff_refs.head_sha).to eq(design.versions.ordered.first.sha)
      end
    end

    context 'there is just one version' do
      let(:versions_count) { 1 }

      it 'builds diff refs based on the empty tree if there was only one version' do
        design = create(:design, :with_file, versions_count: 1)

        expect(design.diff_refs.base_sha).to eq(Gitlab::Git::BLANK_SHA)
        expect(design.diff_refs.head_sha).to eq(design.diff_refs.head_sha)
      end
    end

    it 'has no diff ref if new' do
      design = build(:design)

      expect(design.diff_refs).to be_nil
    end
  end

  describe '#repository' do
    it 'is a design repository' do
      design = build(:design)

      expect(design.repository).to be_a(DesignManagement::Repository)
    end
  end

  # TODO these tests are being temporarily skipped unless run in EE,
  # as we are in the process of moving Design Management to FOSS in 13.0
  # in steps. In the current step the routes have not yet been moved.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283.
  describe '#note_etag_key' do
    it 'returns a correct etag key' do
      skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

      design = create(:design)

      expect(design.note_etag_key).to eq(
        ::Gitlab::Routing.url_helpers.designs_project_issue_path(design.project, design.issue, { vueroute: design.filename })
      )
    end
  end

  describe '#user_notes_count', :use_clean_rails_memory_store_caching do
    let_it_be(:design) { create(:design, :with_file) }

    subject { design.user_notes_count }

    # Note: Cache invalidation tests are in `design_user_notes_count_service_spec.rb`

    it 'returns a count of user-generated notes' do
      create(:diff_note_on_design, noteable: design)

      is_expected.to eq(1)
    end

    it 'does not count notes on other designs' do
      second_design = create(:design, :with_file)
      create(:diff_note_on_design, noteable: second_design)

      is_expected.to eq(0)
    end

    it 'does not count system notes' do
      create(:diff_note_on_design, system: true, noteable: design)

      is_expected.to eq(0)
    end
  end

  describe '#after_note_changed' do
    subject { build(:design) }

    it 'calls #delete_cache on DesignUserNotesCountService' do
      expect_next_instance_of(DesignManagement::DesignUserNotesCountService) do |service|
        expect(service).to receive(:delete_cache)
      end

      subject.after_note_changed(build(:note))
    end

    it 'does not call #delete_cache on DesignUserNotesCountService when passed a system note' do
      expect(DesignManagement::DesignUserNotesCountService).not_to receive(:new)

      subject.after_note_changed(build(:note, :system))
    end
  end

  describe '.for_reference' do
    let_it_be(:design_a) { create(:design) }
    let_it_be(:design_b) { create(:design) }

    it 'avoids extra queries when calling to_reference' do
      designs = described_class.for_reference.where(id: [design_a.id, design_b.id]).to_a

      expect { designs.map(&:to_reference) }.not_to exceed_query_limit(0)
    end
  end

  describe '#to_reference' do
    let(:namespace) { build(:namespace, path: 'sample-namespace') }
    let(:project)   { build(:project, name: 'sample-project', namespace: namespace) }
    let(:group)     { create(:group, name: 'Group', path: 'sample-group') }
    let(:issue)     { build(:issue, iid: 1, project: project) }
    let(:filename)  { 'homescreen.jpg' }
    let(:design)    { build(:design, filename: filename, issue: issue, project: project) }

    context 'when nil argument' do
      let(:reference) { design.to_reference }

      it 'uses the simple format' do
        expect(reference).to eq "#1[homescreen.jpg]"
      end

      context 'when the filename contains spaces, hyphens, periods, single-quotes, underscores and colons' do
        let(:filename) { %q{a complex filename: containing - _ : etc., but still 'simple'.gif} }

        it 'uses the simple format' do
          expect(reference).to eq "#1[#{filename}]"
        end
      end

      context 'when the filename contains HTML angle brackets' do
        let(:filename) { 'a <em>great</em> filename.jpg' }

        it 'uses Base64 encoding' do
          expect(reference).to eq "#1[base64:#{Base64.strict_encode64(filename)}]"
        end
      end

      context 'when the filename contains quotation marks' do
        let(:filename) { %q{a "great" filename.jpg} }

        it 'uses enclosing quotes, with backslash encoding' do
          expect(reference).to eq %q{#1["a \"great\" filename.jpg"]}
        end
      end

      context 'when the filename contains square brackets' do
        let(:filename) { %q{a [great] filename.jpg} }

        it 'uses enclosing quotes' do
          expect(reference).to eq %q{#1["a [great] filename.jpg"]}
        end
      end
    end

    context 'when full is true' do
      it 'returns complete path to the issue' do
        refs = [
          design.to_reference(full: true),
          design.to_reference(project, full: true),
          design.to_reference(group, full: true)
        ]

        expect(refs).to all(eq 'sample-namespace/sample-project#1/designs[homescreen.jpg]')
      end
    end

    context 'when full is false' do
      it 'returns complete path to the issue' do
        refs = [
          design.to_reference(build(:project), full: false),
          design.to_reference(group, full: false)
        ]

        expect(refs).to all(eq 'sample-namespace/sample-project#1[homescreen.jpg]')
      end
    end

    context 'when same project argument' do
      it 'returns bare reference' do
        expect(design.to_reference(project)).to eq("#1[homescreen.jpg]")
      end
    end
  end

  describe 'reference_pattern' do
    let(:match) { described_class.reference_pattern.match(ref) }
    let(:ref) { design.to_reference }
    let(:design) { build(:design, filename: filename) }

    context 'simple_file_name' do
      let(:filename) { 'simple-file-name.jpg' }

      it 'matches :simple_file_name' do
        expect(match[:simple_file_name]).to eq(filename)
      end
    end

    context 'quoted_file_name' do
      let(:filename) { 'simple "file" name.jpg' }

      it 'matches :simple_file_name' do
        expect(match[:escaped_filename].gsub(/\\"/, '"')).to eq(filename)
      end
    end

    context 'Base64 name' do
      let(:filename) { '<>.png' }

      it 'matches base_64_encoded_name' do
        expect(Base64.decode64(match[:base_64_encoded_name])).to eq(filename)
      end
    end
  end

  describe '.by_issue_id_and_filename' do
    let_it_be(:issue_a) { create(:issue) }
    let_it_be(:issue_b) { create(:issue) }

    let_it_be(:design_a) { create(:design, issue: issue_a) }
    let_it_be(:design_b) { create(:design, issue: issue_a) }
    let_it_be(:design_c) { create(:design, issue: issue_b, filename: design_a.filename) }
    let_it_be(:design_d) { create(:design, issue: issue_b, filename: design_b.filename) }

    it_behaves_like 'a where_composite scope', :by_issue_id_and_filename do
      let(:all_results) { [design_a, design_b, design_c, design_d] }
      let(:first_result) { design_a }

      let(:composite_ids) do
        all_results.map { |design| { issue_id: design.issue_id, filename: design.filename } }
      end
    end
  end
end
