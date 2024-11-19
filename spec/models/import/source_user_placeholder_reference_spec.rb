# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUserPlaceholderReference, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:source_user).class_name('Import::SourceUser') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_reference_column) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:alias_version) }
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:source_user_id) }
    it { is_expected.to validate_numericality_of(:numeric_key).only_integer.is_greater_than(0) }
    it { expect(described_class).to validate_jsonb_schema(['composite_key']) }
    it { is_expected.to allow_value({ id: 1 }).for(:composite_key) }
    it { is_expected.to allow_value({ id: '1' }).for(:composite_key) }
    it { is_expected.to allow_value({ foo: '1', bar: 2 }).for(:composite_key) }
    it { is_expected.not_to allow_value({}).for(:composite_key) }
    it { is_expected.not_to allow_value({ id: 'foo' }).for(:composite_key) }
    it { is_expected.not_to allow_value(1).for(:composite_key) }
    it { is_expected.not_to allow_values('Member', 'GroupMember', 'ProjectMember').for(:model) }

    describe '#validate_numeric_or_composite_key_present' do
      def validation_errors(...)
        described_class.new(...).tap(&:validate)
          .errors
          .where(:base)
      end

      it 'must have numeric_key or composite_key present', :aggregate_failures do
        expect(validation_errors).to be_present
        expect(validation_errors(numeric_key: 1)).to be_blank
        expect(validation_errors(composite_key: { id: 1 })).to be_blank
        expect(validation_errors(numeric_key: 1, composite_key: { id: 1 })).to be_present
      end
    end
  end

  describe 'scopes' do
    describe '.model_groups_for_source_user' do
      let_it_be(:source_user_1) { create(:import_source_user) }
      let_it_be(:source_user_2) { create(:import_source_user) }

      let_it_be(:issue_references_1) do
        create_list(
          :import_source_user_placeholder_reference,
          2,
          source_user: source_user_1,
          model: Issue.to_s,
          user_reference_column: 'author_id'
        )
      end

      let_it_be(:note_author_id_reference_1) do
        create(
          :import_source_user_placeholder_reference,
          source_user: source_user_1,
          model: Note.to_s,
          user_reference_column: 'author_id'
        )
      end

      let_it_be(:note_updated_by_id_reference_1) do
        create(
          :import_source_user_placeholder_reference,
          source_user: source_user_1,
          model: Note.to_s,
          user_reference_column: 'updated_by_id'
        )
      end

      let_it_be(:merge_request_reference_2) do
        create(
          :import_source_user_placeholder_reference,
          source_user: source_user_2,
          model: MergeRequest.to_s,
          user_reference_column: 'author_id'
        )
      end

      it 'returns groups of models and user reference columns for a source user' do
        mapped_reference_groups = described_class
          .model_groups_for_source_user(source_user_1)
          .map { |reference_group| [reference_group.model, reference_group.user_reference_column] }

        expect(mapped_reference_groups).to match_array(
          [%w[Note author_id], %w[Note updated_by_id], %w[Issue author_id]]
        )
      end
    end
  end

  it 'is destroyed when source user is destroyed' do
    reference = create(:import_source_user_placeholder_reference)

    expect { reference.source_user.destroy! }.to change { described_class.count }.by(-1)
  end

  describe 'SERIALIZABLE_ATTRIBUTES' do
    subject(:constant) { described_class::SERIALIZABLE_ATTRIBUTES }

    it 'is the expected list of attribute names' do
      expected_elements = %w[
        composite_key
        model
        namespace_id
        numeric_key
        source_user_id
        user_reference_column
        alias_version
      ]

      failure_message = <<-MSG
        Before fixing this spec, ensure that `#{described_class.name}.from_serialized`
        handles receiving older versions of the array by filling in missing values with defaults.

        You are seeing this message because SERIALIZABLE_ATTRIBUTES has changed.
      MSG

      expect(constant).to eq(expected_elements), failure_message
    end
  end

  describe "#aliased_model" do
    let(:source_user_placeholder_reference) { build(:import_source_user_placeholder_reference, model: "Note") }

    subject(:aliased_model) { source_user_placeholder_reference.aliased_model }

    it "gets the model" do
      expect(aliased_model).to eq(Note)
    end

    context "when the model name has changed" do
      let(:source_user_placeholder_reference) do
        build(:import_source_user_placeholder_reference, model: "Description")
      end

      before do
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_model).and_return(Note)
      end

      it "uses the new model" do
        expect(aliased_model).to eq(Note)
      end
    end
  end

  describe "#aliased_user_reference_column" do
    let(:source_user_placeholder_reference) do
      build(
        :import_source_user_placeholder_reference, model: "Note", user_reference_column: "author_id",
        alias_version: 1
      )
    end

    subject(:aliased_user_reference_column) { source_user_placeholder_reference.aliased_user_reference_column }

    it "gets the column" do
      expect(aliased_user_reference_column).to eq("author_id")
    end

    context "when the column name has changed" do
      before do
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_column).and_return("user_id")
      end

      it "uses the new column" do
        expect(aliased_user_reference_column).to eq("user_id")
      end
    end
  end

  describe "#aliased_composite_key" do
    let(:source_user_placeholder_reference) do
      build(
        :import_source_user_placeholder_reference,
        model: "Note",
        alias_version: 1,
        composite_key: { "author_id" => 1, "old_id" => 2 }
      )
    end

    before do
      allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_column).and_call_original
      allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_column)
        .with("Note", "old_id", version: 1).and_return("new_id")
    end

    subject(:aliased_composite_key) { source_user_placeholder_reference.aliased_composite_key }

    it "gets the keys for the composite key" do
      expect(aliased_composite_key).to eq("author_id" => 1, "new_id" => 2)
    end
  end

  describe '#to_serialized' do
    let(:reference) do
      build(:import_source_user_placeholder_reference,
        numeric_key: 1,
        namespace_id: 2,
        source_user_id: 3,
        user_reference_column: 'foo',
        model: 'Model',
        alias_version: 4,
        composite_key: { key: 1 }
      )
    end

    subject(:serialized) { reference.to_serialized }

    it { is_expected.to eq('[{"key":1},"Model",2,1,3,"foo",4]') }
  end

  describe '.from_serialized' do
    subject(:from_serialized) { described_class.from_serialized(serialized) }

    context 'when serialized reference is valid' do
      let(:serialized) { '[{"key":1},"Issue",2,null,3,"foo",4]' }

      it 'returns a valid SourceUserPlaceholderReference' do
        expect(from_serialized).to be_a(described_class)
          .and(be_valid)
          .and(have_attributes(
            composite_key: { key: 1 },
            model: 'Issue',
            numeric_key: nil,
            namespace_id: 2,
            source_user_id: 3,
            alias_version: 4,
            user_reference_column: 'foo'
          ))
      end

      it 'sets the created_at' do
        expect(from_serialized.created_at).to be_like_time(Time.zone.now)
      end
    end

    context 'when serialized reference has different number of elements than expected' do
      let(:serialized) { '[{"key":1},"Issue",2,null,3]' }

      it 'raises an exception' do
        expect { from_serialized }.to raise_error(described_class::SerializationError)
      end
    end
  end

  describe 'model_record methods' do
    let_it_be(:source_user_1) { create(:import_source_user) }
    let_it_be(:source_user_2) { create(:import_source_user) }

    # Issue
    let_it_be(:issue_author_id_1) { create(:issue, author_id: source_user_1.placeholder_user_id) }
    let_it_be(:issue_author_id_2) { create(:issue, author_id: source_user_2.placeholder_user_id) }
    let_it_be(:issue_closed_by_id_1) { create(:issue, closed_by_id: source_user_1.placeholder_user_id) }
    let_it_be(:issue_author_id_reference_1) do
      create(
        :import_source_user_placeholder_reference,
        source_user: source_user_1,
        model: Issue.to_s,
        user_reference_column: 'author_id',
        numeric_key: issue_author_id_1.id
      )
    end

    let_it_be(:issue_author_id_reference_2) do
      create(
        :import_source_user_placeholder_reference,
        source_user: source_user_2,
        model: Issue.to_s,
        user_reference_column: 'author_id',
        numeric_key: issue_author_id_2.id
      )
    end

    let_it_be(:issue_closed_by_id_reference_1) do
      create(
        :import_source_user_placeholder_reference,
        source_user: source_user_1,
        model: Issue.to_s,
        user_reference_column: 'closed_by_id',
        numeric_key: issue_closed_by_id_1.id
      )
    end

    # IssueAssignee
    let_it_be(:issue_assignee_1) do
      issue_author_id_1.issue_assignees.create!(
        user_id: source_user_1.placeholder_user_id, issue_id: issue_author_id_1.id
      )
    end

    let_it_be(:issue_assignee_2) do
      issue_author_id_1.issue_assignees.create!(
        user_id: source_user_2.placeholder_user_id, issue_id: issue_author_id_1.id
      )
    end

    let_it_be(:issue_assignee_reference_1) do
      create(
        :import_source_user_placeholder_reference,
        source_user: source_user_1,
        model: IssueAssignee.to_s,
        user_reference_column: 'user_id',
        numeric_key: nil,
        composite_key: { user_id: source_user_1.placeholder_user_id, issue_id: issue_author_id_1.id }
      )
    end

    let_it_be(:issue_assignee_reference_2) do
      create(
        :import_source_user_placeholder_reference,
        source_user: source_user_2,
        model: IssueAssignee.to_s,
        user_reference_column: 'user_id',
        numeric_key: nil,
        composite_key: { user_id: source_user_2.placeholder_user_id, issue_id: issue_author_id_1.id }
      )
    end

    describe '#model_record' do
      it 'returns the numeric pkey model record the placeholder reference refers to' do
        expect(issue_author_id_reference_1.model_record).to eq(issue_author_id_1)
      end

      it 'returns the composite key model record the placeholder reference refers to' do
        record = issue_assignee_reference_1.model_record

        expect([record.user_id, record.issue_id]).to eq([issue_assignee_1.user_id, issue_assignee_1.issue_id])
      end

      context 'when the model record no longer belongs the reference\'s placeholder user' do
        let!(:another_user) { create(:user) }

        before do
          issue_closed_by_id_1.update!(closed_by_id: another_user.id)
        end

        it 'does not return the record' do
          expect(issue_closed_by_id_reference_1.model_record).to be_nil
        end
      end
    end

    describe '.model_relations_for_source_user_reference', :aggregate_failures do
      it 'yields numeric pkey model relations and placeholder reference relation' do
        expect do |block|
          described_class.model_relations_for_source_user_reference(
            model: 'Issue', source_user: source_user_1, user_reference_column: 'author_id',
            alias_version: 1, &block
          )
        end.to yield_with_args(
          [
            match_array(issue_author_id_1),
            match_array(issue_author_id_reference_1)
          ]
        )
      end

      it 'yields composite key model relation and placeholder reference relation' do
        expect do |block|
          described_class.model_relations_for_source_user_reference(
            model: 'IssueAssignee', source_user: source_user_1, user_reference_column: 'user_id',
            alias_version: 1, &block
          )
        end.to yield_with_args(
          [
            match_array(have_attributes(user_id: issue_assignee_1.user_id, issue_id: issue_assignee_1.issue_id)),
            match_array(issue_assignee_reference_1)
          ]
        )
      end

      context 'when a placeholder record exists but the record does not belong to a placeholder' do
        let!(:another_user) { create(:user) }

        before do
          issue_closed_by_id_1.update!(closed_by_id: another_user.id)
        end

        it 'does not yield the record' do
          expect do |block|
            described_class.model_relations_for_source_user_reference(
              model: 'Issue', source_user: source_user_1, user_reference_column: 'closed_by_id',
              alias_version: 1, &block
            )
          end.not_to yield_control
        end
      end

      context 'when a placeholder reference does not map to a real model' do
        let!(:invalid_model) { 'ThisWillNeverMapToARealModel' }
        let!(:user_reference_column) { 'user_id' }

        let!(:invalid_placeholder_reference) do
          create(
            :import_source_user_placeholder_reference,
            source_user: source_user_1,
            model: invalid_model,
            user_reference_column: user_reference_column
          )
        end

        before do
          allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        end

        it 'raises an error' do
          expect do |block|
            described_class.model_relations_for_source_user_reference(
              model: invalid_model, source_user: source_user_1, user_reference_column: user_reference_column,
              alias_version: 1, &block
            )
          end.to raise_error(Import::PlaceholderReferences::AliasResolver::MissingAlias)
        end
      end
    end
  end
end
