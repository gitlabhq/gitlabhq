# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Label, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }

  describe 'modules' do
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Subscribable) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:issues).through(:label_links).source(:target) }
    it { is_expected.to have_many(:label_links).dependent(:destroy) }
    it { is_expected.to have_many(:lists).dependent(:destroy) }
    it { is_expected.to have_many(:priorities).class_name('LabelPriority') }
  end

  it_behaves_like 'BaseLabel'

  describe 'validation' do
    it { is_expected.to validate_uniqueness_of(:title).scoped_to([:group_id, :project_id]) }

    describe 'description length' do
      let(:invalid_description) { 'x' * (::Label::DESCRIPTION_LENGTH_MAX + 1) }
      let(:valid_description) { 'short description' }
      let(:label) { build(:label, project: project, description: description) }

      let(:error_message) do
        format(
          _('is too long (%{size}). The maximum size is %{max_size}.'),
          size: ActiveSupport::NumberHelper.number_to_human_size(invalid_description.bytesize),
          max_size: ActiveSupport::NumberHelper.number_to_human_size(::Label::DESCRIPTION_LENGTH_MAX)
        )
      end

      subject(:validate) { label.validate }

      context 'when label is a new record' do
        context 'when description exceeds the maximum size' do
          let(:description) { invalid_description }

          it 'adds a description too long error' do
            validate

            expect(label.errors[:description]).to contain_exactly(error_message)
          end
        end

        context 'when description is within the allowed limits' do
          let(:description) { valid_description }

          it 'does not add a validation error' do
            validate

            expect(label.errors).not_to have_key(:description)
          end
        end
      end

      context 'when label is an existing record' do
        before do
          label.description = existing_description
          label.save!(validate: false)
          label.description = description
        end

        context 'when record already had a valid description' do
          let(:existing_description) { 'small difference so it triggers description_changed?' }

          context 'when new description exceeds the maximum size' do
            let(:description) { invalid_description }

            it 'adds a description too long error' do
              validate

              expect(label.errors[:description]).to contain_exactly(error_message)
            end
          end

          context 'when new description is within the allowed limits' do
            let(:description) { valid_description }

            it 'does not add a validation error' do
              validate

              expect(label.errors).not_to have_key(:description)
            end
          end
        end

        context 'when record existed with an invalid description' do
          let(:existing_description) { "#{invalid_description} small difference so it triggers description_changed?" }

          context 'when description is not changed' do
            let(:description) { existing_description }

            it 'does not add a validation error' do
              validate

              expect(label.errors).not_to have_key(:description)
            end
          end

          context 'when new description exceeds the maximum size' do
            context 'when new description is shorter than existing description' do
              let(:description) { invalid_description }

              it 'allows updating descriptions that already existed above the limit' do
                validate

                expect(label.errors).not_to have_key(:description)
              end
            end

            context 'when new description is longer than existing description' do
              let(:description) { "#{existing_description}1" }

              it 'adds a description too long error' do
                validate

                expect(label.errors[:description]).to contain_exactly(error_message)
              end
            end
          end

          context 'when new description is within the allowed limits' do
            let(:description) { valid_description }

            it 'does not add a validation error' do
              validate

              expect(label.errors).not_to have_key(:description)
            end
          end
        end
      end
    end
  end

  describe 'ensure_lock_on_merge_allowed' do
    let(:validation_error) { 'can not be set for template labels' }

    # rubocop:disable Rails/SaveBang
    context 'when creating a label' do
      let(:label) { described_class.create(title: 'test', template: template, lock_on_merge: lock_on_merge) }

      where(:template, :lock_on_merge, :valid, :errors) do
        false         | false        | true    | []
        false         | true         | true    | []
        true          | false        | true    | []
        true          | true         | false   | [validation_error]
        false         | true         | true    | []
      end

      with_them do
        it 'validates lock_on_merge on label creation' do
          expect(label.valid?).to be(valid)
          expect(label.errors[:lock_on_merge]).to eq(errors)
        end
      end
    end
    # rubocop:enable Rails/SaveBang

    context 'when updating a label' do
      let_it_be(:template_label) { create(:label, template: true) }

      where(:lock_on_merge, :valid, :errors) do
        true         | false   | [validation_error]
        false        | true    | []
      end

      with_them do
        it 'validates lock_on_merge value if label is a template' do
          template_label.update_column(:lock_on_merge, lock_on_merge)

          expect(template_label.valid?).to be(valid)
          expect(template_label.errors[:lock_on_merge]).to eq(errors)
        end
      end
    end
  end

  describe 'scopes' do
    describe '.on_board' do
      let(:board) { create(:board, project: project) }
      let!(:list1) { create(:list, board: board, label: development) }
      let!(:list2) { create(:list, board: board, label: testing) }

      let!(:development) { create(:label, project: project, name: 'Development') }
      let!(:testing) { create(:label, project: project, name: 'Testing') }
      let!(:regression) { create(:label, project: project, name: 'Regression') }

      it 'returns only the board labels' do
        expect(described_class.on_board(board.id)).to match_array([development, testing])
      end
    end

    describe '.with_lock_on_merge' do
      let(:label) { create(:label, project: project, name: 'Label') }
      let(:label_locked) { create(:label, project: project, name: 'Label locked', lock_on_merge: true) }

      it 'return only locked labels' do
        expect(described_class.with_lock_on_merge).to match_array([label_locked])
      end
    end
  end

  describe 'destroying labels' do
    context 'when lock_on_merge is true' do
      it 'prevents label from being destroyed' do
        label = create(:label, lock_on_merge: true)

        expect(label.destroy).to be false
        expect(label.errors.full_messages).to include("#{label.name} is locked and was not removed")
      end
    end

    context 'when lock_on_merge is false' do
      it 'allows label to be destroyed' do
        label = create(:label, lock_on_merge: false)

        expect(label.destroy).to eq label
        expect(label.destroyed?).to be_truthy
      end
    end
  end

  describe '#hook_attrs' do
    let_it_be(:label) { build_stubbed(:label) }

    subject(:attrs) { label.hook_attrs }

    it 'has the expected attributes' do
      is_expected.to match(
        {
          id: label.id,
          title: label.title,
          color: label.color,
          project_id: label.project.id,
          created_at: be_like_time(label.created_at),
          updated_at: be_like_time(label.updated_at),
          template: label.template,
          description: label.description,
          type: label.type,
          group_id: nil
        }
      )
    end

    context 'when label has a group' do
      let_it_be(:group) { build_stubbed(:group) }

      before do
        label.group_id = group.id
      end

      it 'has the group ID' do
        is_expected.to include(group_id: group.id)
      end
    end
  end

  describe 'priorization' do
    subject(:label) { create(:label, project: project) }

    describe '#prioritize!' do
      context 'when label is not prioritized' do
        it 'creates a label priority' do
          expect { label.prioritize!(project, 1) }.to change(label.priorities, :count).by(1)
        end

        it 'sets label priority' do
          label.prioritize!(project, 1)

          expect(label.priorities.first.priority).to eq 1
        end
      end

      context 'when label is prioritized' do
        let!(:priority) { create(:label_priority, project: project, label: label, priority: 0) }

        it 'does not create a label priority' do
          expect { label.prioritize!(project, 1) }.not_to change(label.priorities, :count)
        end

        it 'updates label priority' do
          label.prioritize!(project, 1)

          expect(priority.reload.priority).to eq 1
        end
      end
    end

    describe '#unprioritize!' do
      it 'removes label priority' do
        create(:label_priority, project: project, label: label, priority: 0)

        expect { label.unprioritize!(project) }.to change(label.priorities, :count).by(-1)
      end
    end

    describe '#priority' do
      context 'when label is not prioritized' do
        it 'returns nil' do
          expect(label.priority(project)).to be_nil
        end
      end

      context 'when label is prioritized' do
        it 'returns label priority' do
          create(:label_priority, project: project, label: label, priority: 1)

          expect(label.priority(project)).to eq 1
        end
      end
    end
  end

  describe '.subscribed_by' do
    let!(:user)   { create(:user) }
    let!(:label)  { create(:label) }
    let!(:label2) { create(:label) }

    before do
      label.subscribe(user)
    end

    it 'returns subscribed labels' do
      expect(described_class.subscribed_by(user.id)).to eq([label])
    end

    it 'returns nothing' do
      expect(described_class.subscribed_by(0)).to be_empty
    end
  end

  describe '.top_labels_by_target' do
    let(:label) { create(:label) }
    let(:popular_label) { create(:label) }
    let(:merge_request1) { create(:merge_request) }
    let(:merge_request2) { create(:merge_request) }

    before do
      merge_request1.labels = [label, popular_label]
      merge_request2.labels = [popular_label]
    end

    it 'returns distinct labels, ordered by usage in the given target relation' do
      top_labels = described_class.top_labels_by_target(MergeRequest.all)

      expect(top_labels).to match_array([popular_label, label])
    end

    it 'excludes labels that are not assigned to any records in the given target relation' do
      merge_requests = MergeRequest.where(id: merge_request2.id)
      top_labels = described_class.top_labels_by_target(merge_requests)

      expect(top_labels).to match_array([popular_label])
    end
  end

  describe '.sorted_by_similarity_desc' do
    context 'when sorted by similarity' do
      it 'returns most relevant labels first' do
        label1 = create(:label, title: 'exact')
        label2 = create(:label, title: 'less exact')
        label3 = create(:label, title: 'other', description: 'mentions exact')
        expect(described_class.sorted_by_similarity_desc('exact')).to eq([label1, label2, label3])
      end
    end
  end

  describe '.optionally_subscribed_by' do
    let!(:user)   { create(:user) }
    let!(:label)  { create(:label) }
    let!(:label2) { create(:label) }

    before do
      label.subscribe(user)
    end

    it 'returns subscribed labels' do
      expect(described_class.optionally_subscribed_by(user.id)).to eq([label])
    end

    it 'returns all labels if user_id is nil' do
      expect(described_class.optionally_subscribed_by(nil)).to match_array([label, label2])
    end
  end

  describe '#templates' do
    context 'with invalid template labels' do
      it 'returns only valid template labels' do
        create(:label)
        # Project labels should not have template set to true
        create(:label, template: true)
        valid_template_label = described_class.create!(title: 'test', template: true, type: nil)

        expect(described_class.templates).to eq([valid_template_label])
      end
    end
  end

  describe '.pluck_titles' do
    subject(:pluck_titles) { described_class.pluck_titles }

    it 'returns the audit event type of the event type filter' do
      label1 =  create(:label, title: "TITLE1")
      label2 = create(:label, title: "TITLE2")

      expect(pluck_titles).to contain_exactly(label1.title, label2.title)
    end
  end
end
