# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exportable, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:issue) { create(:issue, project: project, milestone: milestone) }
  let_it_be(:note1) { create(:system_note, project: project, noteable: issue) }
  let_it_be(:note2) { create(:system_note, project: project, noteable: issue) }
  let_it_be(:options) { { include: [{ notes: { only: [:note] }, milestone: { only: :title } }] } }

  let_it_be(:model_klass) do
    Class.new(ApplicationRecord) do
      include Exportable

      belongs_to :project
      has_one :milestone
      has_many :notes

      self.table_name = 'issues'

      def self.name
        'Issue'
      end
    end
  end

  subject { model_klass.new }

  describe '.to_authorized_json' do
    let_it_be(:model_record) { model_klass.new }

    context 'when key to authorize is not an association name' do
      it 'returns string without given key' do
        expect(subject.to_authorized_json([:foo], user, options)).not_to include('foo')
      end
    end

    context 'when key to authorize is an association name' do
      let(:key_to_authorize) { :notes }

      subject(:record_json) { model_record.to_authorized_json([key_to_authorize], user, options) }

      context 'when there are no records' do
        before do
          allow(model_record).to receive(:notes).and_return(Note.none)
        end

        it 'returns string including the empty association' do
          expect(record_json).to include("\"notes\":[]")
        end
      end

      context 'when association has #exportable_record? defined' do
        before do
          allow(model_record).to receive(:try).with(:notes).and_return(issue.notes)
        end

        context 'when user can read all records' do
          before do
            allow_next_found_instance_of(Note) do |note|
              allow(note).to receive(:respond_to?).with(:exportable_record?).and_return(true)
              allow(note).to receive(:exportable_record?).with(user).and_return(true)
            end
          end

          it 'returns string containing all records',
            quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450510' do
            expect(record_json)
              .to include("\"notes\":[{\"note\":\"#{note1.note}\"},{\"note\":\"#{note2.note}\"}]")
          end
        end

        context 'when user can not read records' do
          before do
            allow_next_instance_of(Note) do |note|
              allow(note).to receive(:respond_to?).with(:exportable_record?).and_return(true)
              allow(note).to receive(:exportable_record?).with(user).and_return(false)
            end
          end

          it 'returns string including the empty association' do
            expect(record_json).to include("\"notes\":[]")
          end
        end

        context 'when user can read some records' do
          before do
            allow(model_record).to receive(:readable_records).with(:notes, current_user: user)
                                                             .and_return([note1])
          end

          it 'returns string containing readable records only' do
            expect(record_json).to include("\"notes\":[{\"note\":\"#{note1.note}\"}]")
          end
        end
      end

      context 'when association does not have #exportable_record? defined' do
        before do
          allow(model_record).to receive(:try).with(:notes).and_return([note1])

          allow(note1).to receive(:respond_to?).and_call_original
          allow(note1).to receive(:respond_to?).with(:exportable_record?).and_return(false)
        end

        it 'calls #readable_by?' do
          expect(note1).to receive(:readable_by?).with(user)

          record_json
        end
      end

      context 'with single relation' do
        let(:key_to_authorize) { :milestone }

        before do
          allow(model_record).to receive(:milestone).and_return(issue.milestone)
        end

        context 'when user can read the record' do
          before do
            allow(milestone).to receive(:readable_by?).with(user).and_return(true)
          end

          it 'returns string including association' do
            expect(record_json).to include("\"milestone\":{\"title\":\"#{milestone.title}\"}")
          end
        end

        context 'when user can not read the record' do
          before do
            allow(milestone).to receive(:readable_by?).with(user).and_return(false)
          end

          it 'returns string with null association' do
            expect(record_json).to include("\"milestone\":null")
          end
        end
      end
    end
  end

  describe '.exportable_association?' do
    context 'when model does not respond to association name' do
      it 'returns false' do
        expect(subject.exportable_association?(:tests)).to eq(false)

        allow(issue).to receive(:respond_to?).with(:tests).and_return(false)
      end
    end

    context 'when model responds to association name' do
      let_it_be(:model_record) { model_klass.new }

      context 'when association contains records' do
        before do
          allow(model_record).to receive(:try).with(:milestone).and_return(milestone)
        end

        context 'when current_user is not present' do
          it 'returns false' do
            expect(model_record.exportable_association?(:milestone)).to eq(false)
          end
        end

        context 'when current_user can read association' do
          before do
            allow(milestone).to receive(:readable_by?).with(user).and_return(true)
          end

          it 'returns true' do
            expect(model_record.exportable_association?(:milestone, current_user: user)).to eq(true)
          end
        end

        context 'when current_user can not read association' do
          before do
            allow(milestone).to receive(:readable_by?).with(user).and_return(false)
          end

          it 'returns false' do
            expect(model_record.exportable_association?(:milestone, current_user: user)).to eq(false)
          end
        end
      end

      context 'when association is empty' do
        before do
          allow(model_record).to receive(:try).with(:milestone).and_return(nil)
          allow(milestone).to receive(:readable_by?).with(user).and_return(true)
        end

        it 'returns true' do
          expect(model_record.exportable_association?(:milestone, current_user: user)).to eq(true)
        end
      end

      context 'when association type is has_many' do
        it 'returns true' do
          expect(subject.exportable_association?(:notes)).to eq(true)
        end
      end
    end
  end

  describe '.restricted_associations' do
    let(:model_associations) { [:notes, :labels] }

    context 'when `exportable_restricted_associations` is not defined in inheriting class' do
      it 'returns empty array' do
        expect(subject.restricted_associations(model_associations)).to eq([])
      end
    end

    context 'when `exportable_restricted_associations` is defined in inheriting class' do
      before do
        stub_const('DummyModel', model_klass)

        DummyModel.class_eval do
          def exportable_restricted_associations
            super + [:notes]
          end
        end
      end

      it 'returns empty array if provided key are not restricted' do
        expect(subject.restricted_associations([:labels])).to eq([])
      end

      it 'returns array with restricted keys' do
        expect(subject.restricted_associations(model_associations)).to contain_exactly(:notes)
      end
    end
  end
end
