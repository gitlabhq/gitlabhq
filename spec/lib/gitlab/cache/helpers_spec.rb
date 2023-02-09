# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Helpers, :use_clean_rails_redis_caching do
  subject(:instance) { Class.new.include(described_class).new }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:presenter) { MergeRequestSerializer.new(current_user: user, project: project) }

  before do
    # We have to stub #render as it's a Rails controller method unavailable in
    # the module by itself
    allow(instance).to receive(:render) { |data| data }
    allow(instance).to receive(:current_user) { user }
  end

  describe "#render_cached" do
    let(:method) { :render_cached }
    let(:kwargs) do
      {
        with: presenter,
        project: project
      }
    end

    subject do
      instance.public_send(method, presentable, **kwargs)
    end

    context 'single object' do
      let_it_be(:presentable) { create(:merge_request, source_project: project, source_branch: 'wip') }

      context 'when presenter is a serializer' do
        let(:expected_cache_key_prefix) { 'MergeRequestSerializer' }

        it_behaves_like 'object cache helper'
      end

      context 'when presenter is a Grape::Entity' do
        let(:presenter) { API::Entities::MergeRequest }
        let(:expected_cache_key_prefix) { 'API::Entities::MergeRequest' }

        it_behaves_like 'object cache helper'
      end
    end

    context 'collection of objects' do
      let(:expected_cache_key_prefix) { 'MergeRequestSerializer' }

      let_it_be(:presentable) do
        [
          create(:merge_request, source_project: project, source_branch: 'fix'),
          create(:merge_request, source_project: project, source_branch: 'master')
        ]
      end

      it_behaves_like 'collection cache helper'
    end

    context 'when passed presenter is not a serializer or an entity' do
      let(:presenter) { User }

      let_it_be(:presentable) do
        create(:merge_request, source_project: project, source_branch: 'master')
      end

      it 'throws an exception' do
        expect { subject }.to raise_exception(ArgumentError, "presenter User is not supported")
      end
    end
  end
end
