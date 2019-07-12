# frozen_string_literal: true

require 'spec_helper'

describe Group, 'Routable' do
  let!(:group) { create(:group, name: 'foo') }

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
        group.update(path: 'wow', name: 'much')

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

  describe '.find_by_full_path' do
    let!(:nested_group) { create(:group, parent: group) }

    context 'without any redirect routes' do
      it { expect(described_class.find_by_full_path(group.to_param)).to eq(group) }
      it { expect(described_class.find_by_full_path(group.to_param.upcase)).to eq(group) }
      it { expect(described_class.find_by_full_path(nested_group.to_param)).to eq(nested_group) }
      it { expect(described_class.find_by_full_path('unknown')).to eq(nil) }
    end

    context 'with redirect routes' do
      let!(:group_redirect_route) { group.redirect_routes.create!(path: 'bar') }
      let!(:nested_group_redirect_route) { nested_group.redirect_routes.create!(path: nested_group.path.sub('foo', 'bar')) }

      context 'without follow_redirects option' do
        context 'with the given path not matching any route' do
          it { expect(described_class.find_by_full_path('unknown')).to eq(nil) }
        end

        context 'with the given path matching the canonical route' do
          it { expect(described_class.find_by_full_path(group.to_param)).to eq(group) }
          it { expect(described_class.find_by_full_path(group.to_param.upcase)).to eq(group) }
          it { expect(described_class.find_by_full_path(nested_group.to_param)).to eq(nested_group) }
        end

        context 'with the given path matching a redirect route' do
          it { expect(described_class.find_by_full_path(group_redirect_route.path)).to eq(nil) }
          it { expect(described_class.find_by_full_path(group_redirect_route.path.upcase)).to eq(nil) }
          it { expect(described_class.find_by_full_path(nested_group_redirect_route.path)).to eq(nil) }
        end
      end

      context 'with follow_redirects option set to true' do
        context 'with the given path not matching any route' do
          it { expect(described_class.find_by_full_path('unknown', follow_redirects: true)).to eq(nil) }
        end

        context 'with the given path matching the canonical route' do
          it { expect(described_class.find_by_full_path(group.to_param, follow_redirects: true)).to eq(group) }
          it { expect(described_class.find_by_full_path(group.to_param.upcase, follow_redirects: true)).to eq(group) }
          it { expect(described_class.find_by_full_path(nested_group.to_param, follow_redirects: true)).to eq(nested_group) }
        end

        context 'with the given path matching a redirect route' do
          it { expect(described_class.find_by_full_path(group_redirect_route.path, follow_redirects: true)).to eq(group) }
          it { expect(described_class.find_by_full_path(group_redirect_route.path.upcase, follow_redirects: true)).to eq(group) }
          it { expect(described_class.find_by_full_path(nested_group_redirect_route.path, follow_redirects: true)).to eq(nested_group) }
        end
      end
    end
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
      let!(:nested_group) { create(:group, parent: group) }

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

  describe '#full_path' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }

    it { expect(group.full_path).to eq(group.path) }
    it { expect(nested_group.full_path).to eq("#{group.full_path}/#{nested_group.path}") }
  end

  describe '#full_name' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }

    it { expect(group.full_name).to eq(group.name) }
    it { expect(nested_group.full_name).to eq("#{group.name} / #{nested_group.name}") }
  end
end

describe Project, 'Routable' do
  describe '#full_path' do
    let(:project) { build_stubbed(:project) }

    it { expect(project.full_path).to eq "#{project.namespace.full_path}/#{project.path}" }
  end

  describe '#full_name' do
    let(:project) { build_stubbed(:project) }

    it { expect(project.full_name).to eq "#{project.namespace.human_name} / #{project.name}" }
  end
end
