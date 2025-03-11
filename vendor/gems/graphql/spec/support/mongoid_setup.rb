# frozen_string_literal: true

if testing_mongoid?
  # TODO make this work with existing fixtures
  Mongoid.load_configuration({
    clients: {
      default: {
        database: 'graphql_ruby_test',
        hosts: ['localhost:27017']
      }
    },
    sessions: {
      default: {
        database: 'graphql_ruby_test',
        hosts: ['localhost:27017']
      }
    }
  })
end
