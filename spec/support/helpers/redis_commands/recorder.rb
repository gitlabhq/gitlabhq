# frozen_string_literal: true

module RedisCommands
  class Recorder
    def initialize(pattern: nil, &block)
      @log = []
      @pattern = pattern

      record(&block) if block
    end

    attr_reader :log

    def record(&block)
      ActiveSupport::Notifications.subscribed(method(:callback), 'redis.process_commands', &block)
    end

    def by_command(command)
      @log.select { |record| record.include?(command) }
    end

    def count
      @count ||= @log.count
    end

    private

    def callback(name, start, finish, message_id, values)
      commands = values[:commands]

      @log << commands.flatten if @pattern.nil? || commands.to_s.include?(@pattern)
    end
  end
end
