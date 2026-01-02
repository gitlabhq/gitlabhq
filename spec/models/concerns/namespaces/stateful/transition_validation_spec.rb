# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::TransitionValidation, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:namespace) { create(:namespace) }

  describe 'FORBIDDEN_ANCESTOR_STATES constant' do
    it 'defines forbidden states for each event' do
      expect(described_class::FORBIDDEN_ANCESTOR_STATES).to eq({
        archive: %i[archived deletion_in_progress deletion_scheduled],
        unarchive: %i[deletion_in_progress deletion_scheduled],
        schedule_deletion: %i[deletion_in_progress deletion_scheduled]
      })
    end

    it 'is frozen' do
      expect(described_class::FORBIDDEN_ANCESTOR_STATES).to be_frozen
    end
  end

  describe 'validations' do
    describe 'ancestors_state validations' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:child) { create(:group, parent: parent) }

      after do
        set_state(parent, :ancestor_inherited)
        set_state(child, :ancestor_inherited)
      end

      describe 'blocks transition when parent in blocking state' do
        where(:event, :child_from, :parent_state) do
          :archive           | :ancestor_inherited | :archived
          :archive           | :ancestor_inherited | :deletion_in_progress
          :archive           | :ancestor_inherited | :deletion_scheduled
          :unarchive         | :archived           | :deletion_in_progress
          :unarchive         | :archived           | :deletion_scheduled
          :schedule_deletion | :ancestor_inherited | :deletion_in_progress
          :schedule_deletion | :ancestor_inherited | :deletion_scheduled
          :schedule_deletion | :archived           | :deletion_in_progress
          :schedule_deletion | :archived           | :deletion_scheduled
        end

        with_them do
          it "prevents #{params[:event]} when parent is #{params[:parent_state]}" do
            set_state(parent, parent_state)
            set_state(child, child_from)

            expect { child.public_send(event, transition_user: user) }.not_to change { child.reload.state_name }
            expect(child.errors[:state]).to include(match(/cannot be changed as ancestor ID \d+ is #{parent_state}/))
          end
        end
      end

      describe 'allows transition when namespace has no ancestors' do
        where(:event, :from_state, :to_state) do
          :archive           | :ancestor_inherited | :archived
          :unarchive         | :archived           | :ancestor_inherited
          :schedule_deletion | :ancestor_inherited | :deletion_scheduled
          :schedule_deletion | :archived           | :deletion_scheduled
        end

        with_them do
          it "allows #{params[:event]} for root namespace" do
            set_state(namespace, from_state)

            expect { namespace.public_send(event, transition_user: user) }
              .to change { namespace.reload.state_name }.from(from_state).to(to_state)
            expect(namespace.errors).to be_empty
          end
        end
      end

      describe 'allows transition when parent in allowed state' do
        where(:event, :child_from, :child_to, :parent_state) do
          :archive           | :ancestor_inherited | :archived           | :ancestor_inherited
          :unarchive         | :archived           | :ancestor_inherited | :ancestor_inherited
          :unarchive         | :archived           | :ancestor_inherited | :archived
          :schedule_deletion | :ancestor_inherited | :deletion_scheduled | :ancestor_inherited
          :schedule_deletion | :archived           | :deletion_scheduled | :archived
        end

        with_them do
          it "allows #{params[:event]} when parent is #{params[:parent_state]}" do
            set_state(parent, parent_state)
            set_state(child, child_from)

            expect { child.public_send(event, transition_user: user) }
              .to change { child.reload.state_name }.from(child_from).to(child_to)
            expect(child.errors).to be_empty
          end
        end
      end

      describe 'allows transition regardless of parent state' do
        where(:event, :child_from, :child_to, :parent_state) do
          :start_deletion      | :deletion_scheduled   | :deletion_in_progress | :deletion_scheduled
          :start_deletion      | :deletion_scheduled   | :deletion_in_progress | :deletion_in_progress
          :reschedule_deletion | :deletion_in_progress | :deletion_scheduled   | :deletion_scheduled
          :reschedule_deletion | :deletion_in_progress | :deletion_scheduled   | :deletion_in_progress
          :cancel_deletion     | :deletion_scheduled   | :archived             | :deletion_scheduled
          :cancel_deletion     | :deletion_scheduled   | :ancestor_inherited   | :deletion_scheduled
          :cancel_deletion     | :deletion_in_progress | :archived             | :deletion_in_progress
          :cancel_deletion     | :deletion_in_progress | :ancestor_inherited   | :deletion_in_progress
        end

        with_them do
          before do
            set_state(parent, parent_state)
            set_state(child, child_from)

            allow(child).to receive(:restore_to_archived_on_cancel_deletion?).and_return(true) if child_to == :archived
          end

          it "allows #{params[:event]} when parent is #{params[:parent_state]}" do
            expect { child.public_send(event) }
              .to change { child.reload.state_name }.from(child_from).to(child_to)
            expect(child.errors).to be_empty
          end
        end
      end
    end

    describe 'ensure_transition_user validations' do
      describe 'events requiring transition_user' do
        where(:event, :from_state, :to_state) do
          :schedule_deletion | :ancestor_inherited | :deletion_scheduled
          :schedule_deletion | :archived           | :deletion_scheduled
        end

        with_them do
          before do
            set_state(namespace, from_state)
          end

          it 'blocks transition when transition_user is not provided' do
            expect { namespace.public_send(event) }.not_to change { namespace.reload.state_name }
            expect(namespace.errors[:state]).to include("#{event} transition needs transition_user")
          end

          it 'allows transition when transition_user is provided' do
            expect { namespace.public_send(event, transition_user: user) }
              .to change { namespace.reload.state_name }.from(from_state).to(to_state)
            expect(namespace.errors).to be_empty
          end
        end
      end

      describe 'events not requiring transition_user' do
        where(:event, :from_state, :to_state) do
          :archive             | :ancestor_inherited   | :archived
          :unarchive           | :archived             | :ancestor_inherited
          :start_deletion      | :deletion_scheduled   | :deletion_in_progress
          :reschedule_deletion | :deletion_in_progress | :deletion_scheduled
          :cancel_deletion     | :deletion_scheduled   | :ancestor_inherited
          :cancel_deletion     | :deletion_in_progress | :ancestor_inherited
        end

        with_them do
          before do
            set_state(namespace, from_state)
          end

          it 'allows transition without transition_user' do
            expect { namespace.public_send(event) }
              .to change { namespace.reload.state_name }.from(from_state).to(to_state)
            expect(namespace.errors).to be_empty
          end
        end
      end
    end
  end
end
