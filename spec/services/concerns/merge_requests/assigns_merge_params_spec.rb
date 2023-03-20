# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AssignsMergeParams, feature_category: :code_review_workflow do
  it 'raises an error when used from an instance that does not respond to #current_user' do
    define_class = -> { Class.new { include MergeRequests::AssignsMergeParams }.new }

    expect { define_class.call }.to raise_error %r{can not be included in (.*) without implementing #current_user}
  end

  describe '#assign_allowed_merge_params' do
    let(:merge_request) { build(:merge_request) }

    let(:params) do
      { commit_message: 'Commit Message',
        'should_remove_source_branch' => true,
        unknown_symbol: 'Unknown symbol',
        'unknown_string' => 'Unknown String' }
    end

    subject(:merge_request_service) do
      Class.new do
        attr_accessor :current_user

        include MergeRequests::AssignsMergeParams

        def initialize(user)
          @current_user = user
        end
      end
    end

    it 'only assigns known parameters to the merge request' do
      service = merge_request_service.new(merge_request.author)

      service.assign_allowed_merge_params(merge_request, params)

      expect(merge_request.merge_params).to eq('commit_message' => 'Commit Message', 'should_remove_source_branch' => true)
    end

    it 'returns a hash without the known merge params' do
      service = merge_request_service.new(merge_request.author)

      result = service.assign_allowed_merge_params(merge_request, params)

      expect(result).to eq({ 'unknown_symbol' => 'Unknown symbol', 'unknown_string' => 'Unknown String' })
    end

    context 'the force_remove_source_branch param' do
      let(:params) { { force_remove_source_branch: true } }

      it 'assigns the param if the user is allowed to do that' do
        service = merge_request_service.new(merge_request.author)

        result = service.assign_allowed_merge_params(merge_request, params)

        expect(merge_request.force_remove_source_branch?).to be true
        expect(result).to be_empty
      end

      it 'only removes the param if the user is not allowed to do that' do
        service = merge_request_service.new(build(:user))

        result = service.assign_allowed_merge_params(merge_request, params)

        expect(merge_request.force_remove_source_branch?).to be_falsy
        expect(result).to be_empty
      end
    end
  end
end
