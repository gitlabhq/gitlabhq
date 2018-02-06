require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateEventsToPushEventPayloads::Event, :migration, schema: 20170608152748 do
  describe '#commit_title' do
    it 'returns nil when there are no commits' do
      expect(described_class.new.commit_title).to be_nil
    end

    it 'returns nil when there are commits without commit messages' do
      event = described_class.new

      allow(event).to receive(:commits).and_return([{ id: '123' }])

      expect(event.commit_title).to be_nil
    end

    it 'returns the commit message when it is less than 70 characters long' do
      event = described_class.new

      allow(event).to receive(:commits).and_return([{ message: 'Hello world' }])

      expect(event.commit_title).to eq('Hello world')
    end

    it 'returns the first line of a commit message if multiple lines are present' do
      event = described_class.new

      allow(event).to receive(:commits).and_return([{ message: "Hello\n\nworld" }])

      expect(event.commit_title).to eq('Hello')
    end

    it 'truncates the commit to 70 characters when it is too long' do
      event = described_class.new

      allow(event).to receive(:commits).and_return([{ message: 'a' * 100 }])

      expect(event.commit_title).to eq(('a' * 67) + '...')
    end
  end

  describe '#commit_from_sha' do
    it 'returns nil when pushing to a new ref' do
      event = described_class.new

      allow(event).to receive(:create?).and_return(true)

      expect(event.commit_from_sha).to be_nil
    end

    it 'returns the ID of the first commit when pushing to an existing ref' do
      event = described_class.new

      allow(event).to receive(:create?).and_return(false)
      allow(event).to receive(:data).and_return(before: '123')

      expect(event.commit_from_sha).to eq('123')
    end
  end

  describe '#commit_to_sha' do
    it 'returns nil when removing an existing ref' do
      event = described_class.new

      allow(event).to receive(:remove?).and_return(true)

      expect(event.commit_to_sha).to be_nil
    end

    it 'returns the ID of the last commit when pushing to an existing ref' do
      event = described_class.new

      allow(event).to receive(:remove?).and_return(false)
      allow(event).to receive(:data).and_return(after: '123')

      expect(event.commit_to_sha).to eq('123')
    end
  end

  describe '#data' do
    it 'returns the deserialized data' do
      event = described_class.new(data: { before: '123' })

      expect(event.data).to eq(before: '123')
    end

    it 'returns an empty hash when no data is present' do
      event = described_class.new

      expect(event.data).to eq({})
    end
  end

  describe '#commits' do
    it 'returns an Array of commits' do
      event = described_class.new(data: { commits: [{ id: '123' }] })

      expect(event.commits).to eq([{ id: '123' }])
    end

    it 'returns an empty array when no data is present' do
      event = described_class.new

      expect(event.commits).to eq([])
    end
  end

  describe '#commit_count' do
    it 'returns the number of commits' do
      event = described_class.new(data: { total_commits_count: 2 })

      expect(event.commit_count).to eq(2)
    end

    it 'returns 0 when no data is present' do
      event = described_class.new

      expect(event.commit_count).to eq(0)
    end
  end

  describe '#ref' do
    it 'returns the name of the ref' do
      event = described_class.new(data: { ref: 'refs/heads/master' })

      expect(event.ref).to eq('refs/heads/master')
    end
  end

  describe '#trimmed_ref_name' do
    it 'returns the trimmed ref name for a branch' do
      event = described_class.new(data: { ref: 'refs/heads/master' })

      expect(event.trimmed_ref_name).to eq('master')
    end

    it 'returns the trimmed ref name for a tag' do
      event = described_class.new(data: { ref: 'refs/tags/v1.2' })

      expect(event.trimmed_ref_name).to eq('v1.2')
    end
  end

  describe '#create?' do
    it 'returns true when creating a new ref' do
      event = described_class.new(data: { before: described_class::BLANK_REF })

      expect(event.create?).to eq(true)
    end

    it 'returns false when pushing to an existing ref' do
      event = described_class.new(data: { before: '123' })

      expect(event.create?).to eq(false)
    end
  end

  describe '#remove?' do
    it 'returns true when removing an existing ref' do
      event = described_class.new(data: { after: described_class::BLANK_REF })

      expect(event.remove?).to eq(true)
    end

    it 'returns false when pushing to an existing ref' do
      event = described_class.new(data: { after: '123' })

      expect(event.remove?).to eq(false)
    end
  end

  describe '#push_action' do
    let(:event) { described_class.new }

    it 'returns :created when creating a new ref' do
      allow(event).to receive(:create?).and_return(true)

      expect(event.push_action).to eq(:created)
    end

    it 'returns :removed when removing an existing ref' do
      allow(event).to receive(:create?).and_return(false)
      allow(event).to receive(:remove?).and_return(true)

      expect(event.push_action).to eq(:removed)
    end

    it 'returns :pushed when pushing to an existing ref' do
      allow(event).to receive(:create?).and_return(false)
      allow(event).to receive(:remove?).and_return(false)

      expect(event.push_action).to eq(:pushed)
    end
  end

  describe '#ref_type' do
    let(:event) { described_class.new }

    it 'returns :tag for a tag' do
      allow(event).to receive(:ref).and_return('refs/tags/1.2')

      expect(event.ref_type).to eq(:tag)
    end

    it 'returns :branch for a branch' do
      allow(event).to receive(:ref).and_return('refs/heads/1.2')

      expect(event.ref_type).to eq(:branch)
    end
  end
end

##
# The background migration relies on a temporary table, hence we're migrating
# to a specific version of the database where said table is still present.
#
describe Gitlab::BackgroundMigration::MigrateEventsToPushEventPayloads, :migration, schema: 20170825154015 do
  let(:user_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
    end
  end

  let(:migration) { described_class.new }
  let(:user_class) { table(:users) }
  let(:author) { build(:user).becomes(user_class).tap(&:save!).becomes(User) }
  let(:namespace) { create(:namespace, owner: author) }
  let(:projects) { table(:projects) }
  let(:project) { projects.create(namespace_id: namespace.id, creator_id: author.id) }

  # We can not rely on FactoryBot as the state of Event may change in ways that
  # the background migration does not expect, hence we use the Event class of
  # the migration itself.
  def create_push_event(project, author, data = nil)
    klass = Gitlab::BackgroundMigration::MigrateEventsToPushEventPayloads::Event

    klass.create!(
      action: klass::PUSHED,
      project_id: project.id,
      author_id: author.id,
      data: data
    )
  end

  describe '#perform' do
    it 'returns if data should not be migrated' do
      allow(migration).to receive(:migrate?).and_return(false)

      expect(migration).not_to receive(:find_events)

      migration.perform(1, 10)
    end

    it 'migrates the range of events if data is to be migrated' do
      event1 = create_push_event(project, author, { commits: [] })
      event2 = create_push_event(project, author, { commits: [] })

      allow(migration).to receive(:migrate?).and_return(true)

      expect(migration).to receive(:process_event).twice

      migration.perform(event1.id, event2.id)
    end
  end

  describe '#process_event' do
    it 'processes a regular event' do
      event = double(:event, push_event?: false)

      expect(migration).to receive(:replicate_event)
      expect(migration).not_to receive(:create_push_event_payload)

      migration.process_event(event)
    end

    it 'processes a push event' do
      event = double(:event, push_event?: true)

      expect(migration).to receive(:replicate_event)
      expect(migration).to receive(:create_push_event_payload)

      migration.process_event(event)
    end

    it 'handles an error gracefully' do
      event1 = create_push_event(project, author, { commits: [] })

      expect(migration).to receive(:replicate_event).and_call_original
      expect(migration).to receive(:create_push_event_payload).and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

      migration.process_event(event1)

      expect(described_class::EventForMigration.all.count).to eq(0)
    end
  end

  describe '#replicate_event' do
    it 'replicates the event to the "events_for_migration" table' do
      event = create_push_event(
        project,
        author,
        data: { commits: [] },
        title: 'bla'
      )

      attributes = event
        .attributes.with_indifferent_access.except(:title, :data)

      expect(described_class::EventForMigration)
        .to receive(:create!)
        .with(attributes)

      migration.replicate_event(event)
    end
  end

  describe '#create_push_event_payload' do
    let(:push_data) do
      {
        commits: [],
        ref: 'refs/heads/master',
        before: '156e0e9adc587a383a7eeb5b21ddecb9044768a8',
        after: '0' * 40,
        total_commits_count: 1
      }
    end

    let(:event) do
      create_push_event(project, author, push_data)
    end

    before do
      # The foreign key in push_event_payloads at this point points to the
      # "events_for_migration" table so we need to make sure a row exists in
      # said table.
      migration.replicate_event(event)
    end

    it 'creates a push event payload for an event' do
      payload = migration.create_push_event_payload(event)

      expect(PushEventPayload.count).to eq(1)
      expect(payload.valid?).to eq(true)
    end

    it 'does not create push event payloads for removed events' do
      allow(event).to receive(:id).and_return(-1)

      expect { migration.create_push_event_payload(event) }.to raise_error(ActiveRecord::InvalidForeignKey)

      expect(PushEventPayload.count).to eq(0)
    end

    it 'encodes and decodes the commit IDs from and to binary data' do
      payload = migration.create_push_event_payload(event)
      packed = migration.pack(push_data[:before])

      expect(payload.commit_from).to eq(packed)
      expect(payload.commit_to).to be_nil
    end
  end

  describe '#find_events' do
    it 'returns the events for the given ID range' do
      event1 = create_push_event(project, author, { commits: [] })
      event2 = create_push_event(project, author, { commits: [] })
      event3 = create_push_event(project, author, { commits: [] })
      events = migration.find_events(event1.id, event2.id)

      expect(events.length).to eq(2)
      expect(events.pluck(:id)).not_to include(event3.id)
    end
  end

  describe '#migrate?' do
    it 'returns true when data should be migrated' do
      allow(described_class::Event)
        .to receive(:table_exists?).and_return(true)

      allow(described_class::PushEventPayload)
        .to receive(:table_exists?).and_return(true)

      allow(described_class::EventForMigration)
        .to receive(:table_exists?).and_return(true)

      expect(migration.migrate?).to eq(true)
    end

    it 'returns false if the "events" table does not exist' do
      allow(described_class::Event)
        .to receive(:table_exists?).and_return(false)

      expect(migration.migrate?).to eq(false)
    end

    it 'returns false if the "push_event_payloads" table does not exist' do
      allow(described_class::Event)
        .to receive(:table_exists?).and_return(true)

      allow(described_class::PushEventPayload)
        .to receive(:table_exists?).and_return(false)

      expect(migration.migrate?).to eq(false)
    end

    it 'returns false when the "events_for_migration" table does not exist' do
      allow(described_class::Event)
        .to receive(:table_exists?).and_return(true)

      allow(described_class::PushEventPayload)
        .to receive(:table_exists?).and_return(true)

      allow(described_class::EventForMigration)
        .to receive(:table_exists?).and_return(false)

      expect(migration.migrate?).to eq(false)
    end
  end

  describe '#pack' do
    it 'packs a SHA1 into a 20 byte binary string' do
      packed = migration.pack('156e0e9adc587a383a7eeb5b21ddecb9044768a8')

      expect(packed.bytesize).to eq(20)
    end

    it 'returns nil if the input value is nil' do
      expect(migration.pack(nil)).to be_nil
    end
  end
end
