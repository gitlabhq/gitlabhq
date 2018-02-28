require 'spec_helper'

describe Gitlab::ProjectAuthorizations do
  let(:group) { create(:group) }
  let!(:owned_project) { create(:project) }
  let!(:other_project) { create(:project) }
  let!(:group_project) { create(:project, namespace: group) }

  let(:user) { owned_project.namespace.owner }

  def map_access_levels(rows)
    rows.each_with_object({}) do |row, hash|
      hash[row.project_id] = row.access_level
    end
  end

  before do
    other_project.add_reporter(user)
    group.add_developer(user)
  end

  let(:authorizations) do
    klass = if Group.supports_nested_groups?
              Gitlab::ProjectAuthorizations::WithNestedGroups
            else
              Gitlab::ProjectAuthorizations::WithoutNestedGroups
            end

    klass.new(user).calculate
  end

  it 'returns the correct number of authorizations' do
    expect(authorizations.length).to eq(3)
  end

  it 'includes the correct projects' do
    expect(authorizations.pluck(:project_id))
      .to include(owned_project.id, other_project.id, group_project.id)
  end

  it 'includes the correct access levels' do
    mapping = map_access_levels(authorizations)

    expect(mapping[owned_project.id]).to eq(Gitlab::Access::MASTER)
    expect(mapping[other_project.id]).to eq(Gitlab::Access::REPORTER)
    expect(mapping[group_project.id]).to eq(Gitlab::Access::DEVELOPER)
  end

  if Group.supports_nested_groups?
    context 'with nested groups' do
      let!(:nested_group) { create(:group, parent: group) }
      let!(:nested_project) { create(:project, namespace: nested_group) }

      it 'includes nested groups' do
        expect(authorizations.pluck(:project_id)).to include(nested_project.id)
      end

      it 'inherits access levels when the user is not a member of a nested group' do
        mapping = map_access_levels(authorizations)

        expect(mapping[nested_project.id]).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'uses the greatest access level when a user is a member of a nested group' do
        nested_group.add_master(user)

        mapping = map_access_levels(authorizations)

        expect(mapping[nested_project.id]).to eq(Gitlab::Access::MASTER)
      end
    end
  end
end
