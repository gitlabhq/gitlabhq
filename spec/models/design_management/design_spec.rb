# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::Design do
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:design1) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:design2) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:design3) { create(:design, :with_versions, issue: issue, versions_count: 1) }
  let_it_be(:deleted_design) { create(:design, :with_versions, deleted: true) }

  it_behaves_like 'AtomicInternalId', validate_presence: true do
    let(:internal_id_attribute) { :iid }
    let(:instance) { build(:design, issue: issue) }
    let(:scope) { :project }
    let(:scope_attrs) { { project: instance.project } }
    let(:usage) { :design_management_designs }
  end

  it_behaves_like 'a class that supports relative positioning' do
    let_it_be(:relative_parent) { create(:issue) }

    let(:factory) { :design }
    let(:default_params) { { issue: relative_parent } }
  end

  describe 'relations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_many(:actions) }
    it { is_expected.to have_many(:versions) }
    it { is_expected.to have_many(:authors) }
    it { is_expected.to have_many(:notes).dependent(:delete_all) }
    it { is_expected.to have_many(:user_mentions) }

    describe '#authors' do
      it 'returns unique version authors', :aggregate_failures do
        author = create(:user)
        create_list(:design_version, 2, designs: [design1], author: author)
        version_authors = design1.versions.map(&:author)

        expect(version_authors).to contain_exactly(issue.author, author, author)
        expect(design1.authors).to contain_exactly(issue.author, author)
      end
    end
  end

  describe 'validations' do
    subject(:design) { build(:design, issue: issue) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_length_of(:filename).is_at_most(255) }
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

    describe '.ordered' do
      before_all do
        design1.update!(relative_position: 2)
        design2.update!(relative_position: 1)
        design3.update!(relative_position: nil)
        deleted_design.update!(relative_position: nil)
      end

      it 'sorts by relative position and ID in ascending order' do
        expect(described_class.ordered).to eq([design2, design1, design3, deleted_design])
      end
    end

    describe '.in_creation_order' do
      it 'sorts by ID in ascending order' do
        expect(described_class.in_creation_order).to eq([design1, design2, design3, deleted_design])
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

  describe ".build_full_path" do
    it "builds the full path for a design" do
      design = build(:design, issue: issue, filename: "hello.jpg")
      expected_path = "#{DesignManagement.designs_directory}/issue-#{design.issue.iid}/hello.jpg"

      expect(described_class.build_full_path(issue, design)).to eq(expected_path)
    end
  end

  describe '#visible_in?' do
    let_it_be(:issue) { create(:issue, project: issue.project) }

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
      subject { build(:design, issue: issue) }

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
      let(:design) { build(:design, issue: issue) }

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
      let(:design) { create(:design, :with_versions, issue: issue, versions_count: 1, deleted: true) }

      it 'is falsy' do
        restore_designs(design)

        expect(design).not_to be_deleted
      end
    end
  end

  describe '#participants' do
    let_it_be_with_refind(:design) { create(:design, issue: issue) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:version_author) { create(:user) }
    let_it_be(:note_author) { create(:user) }
    let_it_be(:mentioned_user) { create(:user) }
    let_it_be(:design_version) { create(:design_version, :committed, designs: [design], author: version_author) }
    let_it_be(:note) do
      create(:diff_note_on_design,
        noteable: design,
        issue: issue,
        project: issue.project,
        author: note_author,
        note: mentioned_user.to_reference
      )
    end

    subject { design.participants(current_user) }

    it { is_expected.to be_empty }

    context 'when participants can read the project' do
      before do
        design.project.add_guest(version_author)
        design.project.add_guest(note_author)
        design.project.add_guest(mentioned_user)
      end

      it { is_expected.to contain_exactly(version_author, note_author, mentioned_user) }
    end
  end

  describe "#new_design?" do
    let(:design) { design1 }

    it "is false when there are versions" do
      expect(design1).not_to be_new_design
    end

    it "is true when there are no versions" do
      expect(build(:design, issue: issue)).to be_new_design
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
      design = build(:design, issue: issue, filename: "hello.jpg")
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
        expect(design.diff_refs.base_sha).to eq(Gitlab::Git::BLANK_SHA)
        expect(design.diff_refs.head_sha).to eq(design.diff_refs.head_sha)
      end
    end

    it 'has no diff ref if new' do
      design = build(:design, issue: issue)

      expect(design.diff_refs).to be_nil
    end
  end

  describe '#repository' do
    it 'is a design repository' do
      design = build(:design, issue: issue)

      expect(design.repository).to be_a(DesignManagement::Repository)
    end
  end

  describe '#note_etag_key' do
    it 'returns a correct etag key' do
      design = design1

      expect(design.note_etag_key).to eq(
        ::Gitlab::Routing.url_helpers.designs_project_issue_path(design.project, design.issue, { vueroute: design.filename })
      )
    end
  end

  describe '#user_notes_count', :use_clean_rails_memory_store_caching do
    # Note: Cache invalidation tests are in `design_user_notes_count_service_spec.rb`
    it 'returns a count of user-generated notes' do
      common_attrs = { issue: issue, project: issue.project, author: issue.project.creator }
      design, second_design = create_list(:design, 2, :with_file, issue: issue)
      create(:diff_note_on_design, **common_attrs, noteable: design)
      create(:diff_note_on_design, **common_attrs, system: true, noteable: design)
      create(:diff_note_on_design, **common_attrs, noteable: second_design)

      expect(design.user_notes_count).to eq(1)
    end
  end

  describe '#after_note_changed' do
    it 'calls #delete_cache on DesignUserNotesCountService for non-system notes' do
      design = design1

      expect(design.send(:user_notes_count_service)).to receive(:delete_cache).once

      design.after_note_changed(build(:note, project: issue.project))
      design.after_note_changed(build(:note, :system, project: issue.project))
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
    let(:namespace) { build(:namespace, id: non_existing_record_id, path: 'sample-namespace') }
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
    it 'is nil' do
      expect(described_class.reference_pattern).to be_nil
    end
  end

  describe 'link_reference_pattern' do
    it 'is not nil' do
      expect(described_class.link_reference_pattern).not_to be_nil
    end

    it 'does not match the designs tab' do
      expect(described_class.link_reference_pattern).not_to match(url_for_designs(issue))
    end

    where(:ext) do
      (described_class::SAFE_IMAGE_EXT + described_class::DANGEROUS_IMAGE_EXT).flat_map do |ext|
        [[ext], [ext.upcase]]
      end
    end

    with_them do
      let(:filename) { "my-file.#{ext}" }
      let(:design) { build(:design, issue: issue, filename: filename) }
      let(:url) { url_for_design(design) }
      let(:captures) { described_class.link_reference_pattern.match(url)&.named_captures }

      it 'matches the URL' do
        expect(captures).to include(
          'url_filename' => filename,
          'issue' => issue.iid.to_s,
          'namespace' => design.project.namespace.to_param,
          'project' => design.project.name
        )
      end

      context 'the file needs to be encoded' do
        let(:filename) { "my file.#{ext}" }

        it 'extracts the encoded filename' do
          expect(captures).to include('url_filename' => 'my%20file.' + ext)
        end
      end

      context 'the file is all upper case' do
        let(:filename) { "file.#{ext}".upcase }

        it 'extracts the encoded filename' do
          expect(captures).to include('url_filename' => filename)
        end
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
