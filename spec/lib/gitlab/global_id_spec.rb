# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlobalId do
  describe '.build' do
    let_it_be(:object) { create(:issue) }

    it 'returns a standard GlobalId if only object is passed' do
      expect(described_class.build(object).to_s).to eq(object.to_global_id.to_s)
    end

    it 'returns a GlobalId from params' do
      expect(described_class.build(model_name: 'MyModel', id: 'myid').to_s).to eq(
        'gid://gitlab/MyModel/myid'
      )
    end

    it 'returns a GlobalId from object and `id` param' do
      expect(described_class.build(object, id: 'myid').to_s).to eq(
        'gid://gitlab/Issue/myid'
      )
    end

    it 'returns a GlobalId from object and `model_name` param' do
      expect(described_class.build(object, model_name: 'MyModel').to_s).to eq(
        "gid://gitlab/MyModel/#{object.id}"
      )
    end

    it 'returns an error if model_name and id are not able to be determined' do
      expect { described_class.build(id: 'myid') }.to raise_error(URI::InvalidComponentError)
      expect { described_class.build(model_name: 'MyModel') }.to raise_error(URI::InvalidComponentError)
      expect { described_class.build }.to raise_error(URI::InvalidComponentError)
    end
  end

  describe '.as_global_id' do
    let(:project) { build_stubbed(:project) }

    it 'is the identify function on GlobalID instances' do
      gid = project.to_global_id

      expect(described_class.as_global_id(gid)).to eq(gid)
    end

    it 'wraps URI::GID in GlobalID' do
      uri = described_class.build(model_name: 'Foo', id: 1)

      expect(described_class.as_global_id(uri)).to eq(GlobalID.new(uri))
    end

    it 'cannot coerce Integers without a model name' do
      expect { described_class.as_global_id(1) }
        .to raise_error(described_class::CoerceError, 'Cannot coerce Integer')
    end

    it 'can coerce Integers with a model name' do
      uri = described_class.build(model_name: 'Foo', id: 1)

      expect(described_class.as_global_id(1, model_name: 'Foo')).to eq(GlobalID.new(uri))
    end

    it 'rejects any other value' do
      [:symbol, 'string', nil, [], {}, project].each do |value|
        expect { described_class.as_global_id(value) }.to raise_error(described_class::CoerceError)
      end
    end
  end

  describe '.safe_locate', :aggregate_failures do
    let_it_be(:user) { create(:user) }

    let(:gid) { user.to_global_id }
    let(:args) { [gid] }
    let(:kwargs) { {} }

    subject(:safe_locate) { described_class.safe_locate(*args, **kwargs) }

    it 'returns the located object' do
      is_expected.to eq(user)
    end

    context 'when options are provided' do
      let(:options) { { only: User } }
      let(:kwargs) { { options: } }

      it 'passes options to GlobalID::Locator.locate' do
        expect(GlobalID::Locator).to receive(:locate).with(*args, options).and_call_original

        safe_locate
      end
    end

    context 'when gid is nil' do
      let(:gid) { nil }
      let(:on_error) { instance_double(Proc) }
      let(:kwargs) { { on_error: } }

      it 'returns nil without calling on_error' do
        expect(on_error).not_to receive(:call)

        is_expected.to be_nil
      end
    end

    context 'when gid is a string' do
      let(:gid) { super().to_s }

      it 'returns the located object' do
        is_expected.to eq(user)
      end
    end

    context 'when record does not exist' do
      let(:gid) { described_class.build(model_name: ::User.to_s, id: non_existing_record_id) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when an error is raised' do
      let(:gid) { described_class.build(model_name: 'NonExistent', id: non_existing_record_id) }

      it 'returns nil without raising' do
        expect { safe_locate }.not_to raise_error

        is_expected.to be_nil
      end

      context 'when on_error is provided' do
        let(:on_error) { ->(e) { Gitlab::ErrorTracking.track_exception(e) } }
        let(:kwargs) { { on_error: } }

        it 'calls on_error with the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(an_instance_of(NameError))

          safe_locate
        end
      end
    end
  end
end
