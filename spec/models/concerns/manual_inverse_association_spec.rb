require 'spec_helper'

describe ManualInverseAssociation do
  let(:model) do
    Class.new(MergeRequest) do
      belongs_to :manual_association, class_name: 'MergeRequestDiff', foreign_key: :latest_merge_request_diff_id
      manual_inverse_association :manual_association, :merge_request
    end
  end

  before do
    stub_const("#{described_class}::Model", model)
  end

  let(:instance) { create(:merge_request).becomes(model) }

  describe '.manual_inverse_association' do
    context 'when the relation exists' do
      before do
        instance.create_merge_request_diff
        instance.reload
      end

      it 'loads the relation' do
        expect(instance.manual_association).to be_an_instance_of(MergeRequestDiff)
      end

      it 'does not perform extra queries after loading' do
        instance.manual_association

        expect { instance.manual_association.merge_request }
          .not_to exceed_query_limit(0)
      end

      it 'passes arguments to the default association method, to allow reloading' do
        query_count = ActiveRecord::QueryRecorder.new do
          instance.manual_association
          instance.manual_association(true)
        end.count

        expect(query_count).to eq(2)
      end
    end

    context 'when the relation does not return a value' do
      it 'does not try to set an inverse' do
        expect(instance.manual_association).to be_nil
      end
    end
  end
end
