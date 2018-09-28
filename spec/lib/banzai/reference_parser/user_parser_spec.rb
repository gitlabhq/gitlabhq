require 'spec_helper'

describe Banzai::ReferenceParser::UserParser do
  include ReferenceParserHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, group: group, creator: user) }
  subject { described_class.new(Banzai::RenderContext.new(project, user)) }
  let(:link) { empty_html_link }

  describe '#referenced_by' do
    context 'when the link has a data-group attribute' do
      context 'using an existing group ID' do
        before do
          link['data-group'] = project.group.id.to_s
        end

        it 'returns the users of the group' do
          create(:group_member, group: group, user: user)

          expect(subject.referenced_by([link])).to eq([user])
        end

        it 'returns an empty Array when the group has no users' do
          expect(subject.referenced_by([link])).to eq([])
        end
      end

      context 'using a non-existing group ID' do
        it 'returns an empty Array' do
          link['data-group'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end

    context 'when the link has a data-user attribute' do
      it 'returns an Array of users' do
        link['data-user'] = user.id.to_s

        expect(subject.referenced_by([link])).to eq([user])
      end

      context 'when RequestStore is active', :request_store do
        let(:other_user) { create(:user) }

        it 'does not return users from the first call in the second' do
          link['data-user'] = user.id.to_s

          expect(subject.referenced_by([link])).to eq([user])

          link['data-user'] = other_user.id.to_s

          expect(subject.referenced_by([link])).to eq([other_user])
        end
      end
    end

    context 'when the link has a data-project attribute' do
      context 'using an existing project ID' do
        let(:contributor) { create(:user) }

        before do
          project.add_developer(user)
          project.add_developer(contributor)
        end

        it 'returns the members of a project' do
          link['data-project'] = project.id.to_s

          # This uses an explicit sort to make sure this spec doesn't randomly
          # fail when objects are returned in a different order.
          refs = subject.referenced_by([link]).sort_by(&:id)

          expect(refs).to eq([user, contributor])
        end
      end

      context 'using a non-existing project ID' do
        it 'returns an empty Array' do
          link['data-project'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-group attribute' do
      context 'using an existing group ID' do
        before do
          link['data-group'] = group.id.to_s
        end

        it 'returns the nodes if the user can read the group' do
          expect(Ability).to receive(:allowed?)
            .with(user, :read_group, group)
            .and_return(true)

          expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
        end

        it 'returns an empty Array if the user can not read the group' do
          expect(Ability).to receive(:allowed?)
            .with(user, :read_group, group)
            .and_return(false)

          expect(subject.nodes_visible_to_user(user, [link])).to eq([])
        end
      end

      context 'when the link does not have a data-group attribute' do
        context 'with a data-project attribute' do
          it 'returns the nodes if the attribute value equals the current project ID' do
            link['data-project'] = project.id.to_s

            # Ensure that we dont call for Ability.allowed?
            # When project_id in the node is equal to current project ID
            expect(Ability).not_to receive(:allowed?)

            expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
          end

          it 'returns the nodes if the user can read the project' do
            other_project = create(:project, :public)

            link['data-project'] = other_project.id.to_s

            expect(Ability).to receive(:allowed?)
              .with(user, :read_project, other_project)
              .and_return(true)

            expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
          end

          it 'returns an empty Array if the user can not read the project' do
            other_project = create(:project, :public)

            link['data-project'] = other_project.id.to_s

            expect(Ability).to receive(:allowed?)
              .with(user, :read_project, other_project)
              .and_return(false)

            expect(subject.nodes_visible_to_user(user, [link])).to eq([])
          end
        end

        context 'without a data-project attribute' do
          it 'returns the nodes' do
            expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
          end
        end
      end
    end
  end

  describe '#nodes_user_can_reference' do
    context 'when the link has a data-author attribute' do
      it 'returns the nodes when the user is a member of the project' do
        other_project = create(:project)
        other_project.add_developer(user)

        link['data-project'] = other_project.id.to_s
        link['data-author'] = user.id.to_s

        expect(subject.nodes_user_can_reference(user, [link])).to eq([link])
      end

      it 'returns an empty Array when the project could not be found' do
        link['data-project'] = ''
        link['data-author'] = user.id.to_s

        expect(subject.nodes_user_can_reference(user, [link])).to eq([])
      end

      it 'returns an empty Array when the user could not be found' do
        other_project = create(:project)

        link['data-project'] = other_project.id.to_s
        link['data-author'] = ''

        expect(subject.nodes_user_can_reference(user, [link])).to eq([])
      end

      it 'returns an empty Array when the user is not a team member' do
        other_project = create(:project)

        link['data-project'] = other_project.id.to_s
        link['data-author'] = user.id.to_s

        expect(subject.nodes_user_can_reference(user, [link])).to eq([])
      end

      it 'returns the nodes if the project attribute value equals the current project ID' do
        other_user = create(:user)

        link['data-project'] = project.id.to_s
        link['data-author'] = other_user.id.to_s

        expect(subject.nodes_user_can_reference(user, [link])).to eq([link])
      end
    end

    context 'when the link does not have a data-author attribute' do
      it 'returns the nodes' do
        expect(subject.nodes_user_can_reference(user, [link])).to eq([link])
      end
    end
  end
end
