require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170607121233_convert_custom_notification_settings_to_columns')

describe ConvertCustomNotificationSettingsToColumns, :migration do
  let(:user_class) { table(:users) }

  let(:settings_params) do
    [
      { level: 0, events: [:new_note] }, # disabled, single event
      { level: 3, events: [:new_issue, :reopen_issue, :close_issue, :reassign_issue] }, # global, multiple events
      { level: 5, events: described_class::EMAIL_EVENTS }, # custom, all events
      { level: 5, events: [] } # custom, no events
    ]
  end

  let(:notification_settings_before) do
    settings_params.map do |params|
      events = {}

      params[:events].each do |event|
        events[event] = true
      end

      user = user_class.create!(email: "user-#{SecureRandom.hex}@example.org", username: "user-#{SecureRandom.hex}", encrypted_password: '12345678')
      create_params = { user_id: user.id, level: params[:level], events: events }
      notification_setting = described_class::NotificationSetting.create(create_params)

      [notification_setting, params]
    end
  end

  let(:notification_settings_after) do
    settings_params.map do |params|
      events = {}

      params[:events].each do |event|
        events[event] = true
      end

      user = user_class.create!(email: "user-#{SecureRandom.hex}@example.org", username: "user-#{SecureRandom.hex}", encrypted_password: '12345678')
      create_params = events.merge(user_id: user.id, level: params[:level])
      notification_setting = described_class::NotificationSetting.create(create_params)

      [notification_setting, params]
    end
  end

  describe '#up' do
    it 'migrates all settings where a custom event is enabled, even if they are not currently using the custom level' do
      notification_settings_before

      described_class.new.up

      notification_settings_before.each do |(notification_setting, params)|
        notification_setting.reload

        expect(notification_setting.read_attribute_before_type_cast(:events)).to be_nil
        expect(notification_setting.level).to eq(params[:level])

        described_class::EMAIL_EVENTS.each do |event|
          # We don't set the others to false, just let them default to nil
          expected = params[:events].include?(event) || nil

          expect(notification_setting.read_attribute(event)).to eq(expected)
        end
      end
    end
  end

  describe '#down' do
    it 'creates a custom events hash for all settings where at least one event is enabled' do
      notification_settings_after

      described_class.new.down

      notification_settings_after.each do |(notification_setting, params)|
        notification_setting.reload

        expect(notification_setting.level).to eq(params[:level])

        if params[:events].empty?
          # We don't migrate empty settings
          expect(notification_setting.events).to eq({})
        else
          described_class::EMAIL_EVENTS.each do |event|
            expected = params[:events].include?(event)

            expect(notification_setting.events[event]).to eq(expected)
            expect(notification_setting.read_attribute(event)).to be_nil
          end
        end
      end
    end

    it 'reverts the database to the state it was in before' do
      notification_settings_before

      described_class.new.up
      described_class.new.down

      notification_settings_before.each do |(notification_setting, params)|
        notification_setting.reload

        expect(notification_setting.level).to eq(params[:level])

        if params[:events].empty?
          # We don't migrate empty settings
          expect(notification_setting.events).to eq({})
        else
          described_class::EMAIL_EVENTS.each do |event|
            expected = params[:events].include?(event)

            expect(notification_setting.events[event]).to eq(expected)
            expect(notification_setting.read_attribute(event)).to be_nil
          end
        end
      end
    end
  end
end
