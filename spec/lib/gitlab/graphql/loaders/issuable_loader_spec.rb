# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::IssuableLoader do
  subject { described_class.new(parent, finder) }

  let(:params) { HashWithIndifferentAccess.new }

  describe '#find_all' do
    let(:finder) { double(:finder, params: params, execute: %i[x y z]) }

    where(:factory, :param_name) do
      %i[project group].map { |thing| [thing, :"#{thing}_id"] }
    end

    with_them do
      let(:parent) { build_stubbed(factory) }

      it 'assignes the parent parameter, and batching_find_alls the finder' do
        expect(subject.find_all).to contain_exactly(:x, :y, :z)
        expect(params).to include(param_name => parent)
      end
    end

    context 'the parent is of an unexpected type' do
      let(:parent) { build(:merge_request) }

      it 'raises an error if we pass an unexpected parent' do
        expect { subject.find_all }.to raise_error(/Unexpected parent/)
      end
    end
  end

  describe '#batching_find_all' do
    context 'the finder params are anything other than [iids]' do
      let(:finder) { double(:finder, params: params, execute: [:foo]) }
      let(:parent) { build_stubbed(:project) }

      it 'batching_find_alls the finder, setting the correct parent parameter' do
        expect(subject.batching_find_all).to eq([:foo])
        expect(params[:project_id]).to eq(parent)
      end

      it 'allows a post-process block' do
        expect(subject.batching_find_all(&:first)).to eq(:foo)
      end
    end

    context 'the finder params are exactly [iids]' do
      # Dumb finder class, that only implements what we need, and has
      # predictable query counts.
      let(:finder_class) do
        Class.new do
          attr_reader :current_user, :params

          def initialize(user, args)
            @current_user = user
            @params = HashWithIndifferentAccess.new(args.to_h)
          end

          def execute
            params[:project_id].issues.where(iid: params[:iids])
          end
        end
      end

      it 'batches requests' do
        issue_a = create(:issue)
        issue_b = create(:issue)
        issue_c = create(:issue, project: issue_a.project)
        proj_1 = issue_a.project
        proj_2 = issue_b.project
        user = create(:user, developer_projects: [proj_1, proj_2])

        finder_a = finder_class.new(user, iids: [issue_a.iid])
        finder_b = finder_class.new(user, iids: [issue_b.iid])
        finder_c = finder_class.new(user, iids: [issue_c.iid])

        results = []

        expect do
          results.concat(described_class.new(proj_1, finder_a).batching_find_all)
          results.concat(described_class.new(proj_2, finder_b).batching_find_all)
          results.concat(described_class.new(proj_1, finder_c).batching_find_all)
        end.not_to exceed_query_limit(0)

        expect do
          results = results.map(&:sync)
        end.not_to exceed_query_limit(2)

        expect(results).to contain_exactly(issue_a, issue_b, issue_c)
      end
    end
  end
end
