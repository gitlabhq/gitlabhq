# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::CommonHelpers do
  include Rack::Test::Methods

  subject do
    Class.new(Grape::API) do
      helpers API::Helpers::CommonHelpers

      before do
        coerce_nil_params_to_array!
      end

      params do
        requires :id, type: String
        optional :array, type: Array, coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
        optional :array_of_strings, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
        optional :array_of_ints, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce
      end
      get ":id" do
        params.to_json
      end
    end
  end

  def app
    subject
  end

  describe '.coerce_nil_params_to_array!' do
    let(:json_response) { Gitlab::Json.parse(last_response.body) }

    it 'converts all nil parameters to empty arrays' do
      get '/test?array=&array_of_strings=&array_of_ints='

      expect(json_response['array']).to eq([])
      expect(json_response['array_of_strings']).to eq([])
      expect(json_response['array_of_ints']).to eq([])
    end

    it 'leaves non-nil parameters alone' do
      get '/test?array=&array_of_strings=test,me&array_of_ints=1,2'

      expect(json_response['array']).to eq([])
      expect(json_response['array_of_strings']).to eq(%w[test me])
      expect(json_response['array_of_ints']).to eq([1, 2])
    end
  end
end
