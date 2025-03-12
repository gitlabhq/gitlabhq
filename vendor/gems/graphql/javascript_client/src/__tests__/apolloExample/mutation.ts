import { gql } from '@apollo/client';

export const UPDATE_SOMETHING = gql`
mutation UpdateSomething($name: String!) {
  updateSomething(name: $name) { name }
}
`
