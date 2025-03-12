class MyAppSchema < GraphQL::Schema
  query { Types::Query }
  mutation { Types::Mutation }
  subscription { Types::Subscription }
end
