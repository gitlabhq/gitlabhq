# frozen_string_literal: true

RSpec.shared_examples 'a model with paper trail configured' do
  describe 'paper_trail' do
    subject(:object) { create(factory) } # rubocop:disable Rails/SaveBang -- False positive, this is a factory bot method.

    # making duplication of object, and it does not reload when object updated
    let(:new_object_before_change) { object }

    shared_examples 'saving additional properties' do
      it 'saves additional properties' do
        version = object.versions.last

        additional_properties.each do |attr, value|
          expect(version[attr]).to eq(value)
        end
      end
    end

    context 'on creation' do
      it 'contains version with 1' do
        expect(object.versions.length).to be 1
      end

      it 'create version has nil object' do
        expect(object.versions[0].reify).to be_nil
      end

      it_behaves_like 'saving additional properties'
    end

    context 'on update' do
      before do
        object.update!(attributes_to_update)
      end

      it 'contains version with 2' do
        expect(object.versions.length).to be 2
      end

      it 'contains version before update' do
        reified_object = object.versions.last.reify

        expect(reified_object).to eql(object)
      end

      it_behaves_like 'saving additional properties'
    end

    context 'on destroy' do
      before do
        object.destroy!
      end

      it 'contains version with 2' do
        expect(object.versions.length).to be 2
      end

      it 'contains version before destroy' do
        reified_object = object.versions.last.reify

        expect(reified_object).to eql(object)
      end

      it_behaves_like 'saving additional properties'
    end

    context 'on delete' do
      before do
        object.delete
      end

      it 'contains version with 1' do
        expect(object.versions.length).to be 1
      end

      it 'does not contain version before delete' do
        reified_object = object.versions.last.reify

        expect(reified_object).to be_nil
      end
    end

    context 'on touch' do
      before do
        object.touch
      end

      it 'contains version with 2' do
        expect(object.versions.length).to be 2
      end

      it 'contains version before touch' do
        reified_object = object.versions.last.reify

        expect(reified_object).to eql(new_object_before_change)
      end

      it_behaves_like 'saving additional properties'
    end
  end
end
