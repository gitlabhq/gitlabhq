# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'routable resource' do
  describe '.find_by_full_path', :aggregate_failures do
    it 'finds records by their full path' do
      expect(described_class.find_by_full_path(record.full_path)).to eq(record)
      expect(described_class.find_by_full_path(record.full_path.upcase)).to eq(record)
    end

    it 'returns nil for unknown paths' do
      expect(described_class.find_by_full_path('unknown')).to be_nil
    end

    it 'includes route information when loading a record' do
      control_count = ActiveRecord::QueryRecorder.new do
        described_class.find_by_full_path(record.full_path)
      end.count

      expect do
        described_class.find_by_full_path(record.full_path).route
      end.not_to exceed_all_query_limit(control_count)
    end

    context 'when path is a negative number' do
      it 'returns nil' do
        expect(described_class.find_by_full_path(-1)).to be_nil
      end
    end

    context 'with redirect routes' do
      let_it_be(:redirect_route) { create(:redirect_route, source: record) }

      context 'without follow_redirects option' do
        it 'does not find records by their redirected path' do
          expect(described_class.find_by_full_path(redirect_route.path)).to be_nil
          expect(described_class.find_by_full_path(redirect_route.path.upcase)).to be_nil
        end
      end

      context 'with follow_redirects option set to true' do
        it 'finds records by their canonical path' do
          expect(described_class.find_by_full_path(record.full_path, follow_redirects: true)).to eq(record)
          expect(described_class.find_by_full_path(record.full_path.upcase, follow_redirects: true)).to eq(record)
        end

        it 'finds records by their redirected path' do
          expect(described_class.find_by_full_path(redirect_route.path, follow_redirects: true)).to eq(record)
          expect(described_class.find_by_full_path(redirect_route.path.upcase, follow_redirects: true)).to eq(record)
        end

        it 'returns nil for unknown paths' do
          expect(described_class.find_by_full_path('unknown', follow_redirects: true)).to be_nil
        end
      end
    end
  end
end

RSpec.shared_examples 'routable resource with parent' do
  it_behaves_like 'routable resource'

  describe '#full_path' do
    it { expect(record.full_path).to eq "#{record.parent.full_path}/#{record.path}" }

    it 'hits the cache when not preloaded' do
      forcibly_hit_cached_lookup(record, :full_path)

      expect(record.full_path).to eq("#{record.parent.full_path}/#{record.path}")
    end
  end

  describe '#full_name' do
    it { expect(record.full_name).to eq "#{record.parent.human_name} / #{record.name}" }

    context 'without route name' do
      before do
        stub_feature_flags(cached_route_lookups: true)
        record.route.update_attribute(:name, nil)
      end

      it 'builds full name' do
        expect(record.full_name).to eq("#{record.parent.human_name} / #{record.name}")
      end
    end

    it 'hits the cache when not preloaded' do
      forcibly_hit_cached_lookup(record, :full_name)

      expect(record.full_name).to eq("#{record.parent.human_name} / #{record.name}")
    end
  end
end

RSpec.describe Group, 'Routable', :with_clean_rails_cache do
  let_it_be_with_reload(:group) { create(:group, name: 'foo') }
  let_it_be(:nested_group) { create(:group, parent: group) }

  it_behaves_like 'routable resource' do
    let_it_be(:record) { group }
  end

  it_behaves_like 'routable resource with parent' do
    let_it_be(:record) { nested_group }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:route) }
  end

  describe 'Associations' do
    it { is_expected.to have_one(:route).dependent(:destroy) }
    it { is_expected.to have_many(:redirect_routes).dependent(:destroy) }
  end

  describe 'Callbacks' do
    context 'for a group' do
      it 'creates route record on create' do
        expect(group.route.path).to eq(group.path)
        expect(group.route.name).to eq(group.name)
      end

      it 'updates route record on path change' do
        group.update!(path: 'wow', name: 'much')

        expect(group.route.path).to eq('wow')
        expect(group.route.name).to eq('much')
      end

      it 'ensure route path uniqueness across different objects' do
        create(:group, parent: group, path: 'xyz')
        duplicate = build(:project, namespace: group, path: 'xyz')

        expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Path has already been taken')
      end
    end

    context 'for a user' do
      let(:user) { create(:user, username: 'jane', name: "Jane Doe") }

      it 'creates the route for a record on create' do
        expect(user.namespace.name).to eq('Jane Doe')
        expect(user.namespace.path).to eq('jane')
      end

      it 'updates routes and nested routes on name change' do
        project = create(:project, path: 'work-stuff', name: 'Work stuff', namespace: user.namespace)

        user.update!(username: 'jaen', name: 'Jaen Did')
        project.reload

        expect(user.namespace.name).to eq('Jaen Did')
        expect(user.namespace.path).to eq('jaen')
        expect(project.full_name).to eq('Jaen Did / Work stuff')
        expect(project.full_path).to eq('jaen/work-stuff')
      end
    end
  end

  it 'creates route with namespace referencing group' do
    expect(group.route).not_to be_nil
    expect(group.route.namespace).to eq(group)
  end

  describe '.where_full_path_in' do
    context 'without any paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in([])).to eq([])
      end
    end

    context 'without any valid paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in(%w[unknown])).to eq([])
      end
    end

    context 'with valid paths' do
      it 'returns the projects matching the paths' do
        result = described_class.where_full_path_in([group.to_param, nested_group.to_param])

        expect(result).to contain_exactly(group, nested_group)
      end

      it 'returns projects regardless of the casing of paths' do
        result = described_class.where_full_path_in([group.to_param.upcase, nested_group.to_param.upcase])

        expect(result).to contain_exactly(group, nested_group)
      end
    end
  end

  describe '#parent_loaded?' do
    before do
      group.parent = create(:group)
      group.save!

      group.reload
    end

    it 'is false when the parent is not loaded' do
      expect(group.parent_loaded?).to be_falsey
    end

    it 'is true when the parent is loaded' do
      group.parent

      expect(group.parent_loaded?).to be_truthy
    end
  end

  describe '#route_loaded?' do
    it 'is false when the route is not loaded' do
      expect(group.route_loaded?).to be_falsey
    end

    it 'is true when the route is loaded' do
      group.route

      expect(group.route_loaded?).to be_truthy
    end
  end
end

RSpec.describe Project, 'Routable', :with_clean_rails_cache do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  it_behaves_like 'routable resource with parent' do
    let_it_be(:record) { project }
  end

  it 'creates route with namespace referencing project namespace' do
    expect(project.route).not_to be_nil
    expect(project.route.namespace).to eq(project.project_namespace)
  end
end

RSpec.describe Namespaces::ProjectNamespace, 'Routable', :with_clean_rails_cache do
  let_it_be(:group) { create(:group) }

  it 'skips route creation for the resource' do
    expect do
      described_class.create!(project: nil, parent: group, visibility_level: Gitlab::VisibilityLevel::PUBLIC, path: 'foo', name: 'foo')
    end.not_to change { Route.count }
  end
end

def forcibly_hit_cached_lookup(record, method)
  stub_feature_flags(cached_route_lookups: true)
  expect(record).to receive(:persisted?).and_return(true)
  expect(record).to receive(:route_loaded?).and_return(false)
  expect(record).to receive(:parent_loaded?).and_return(false)
  expect(Gitlab::Cache).to receive(:fetch_once).with([record.cache_key, method]).and_call_original
end
