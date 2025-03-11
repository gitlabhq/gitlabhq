import { gql } from '@apollo/client';
import { MORE_FIELDS } from './fragment';

export const GET_HELLO_WORLD = gql`
query getHelloWorld {
  helloWorld
  ... MoreFields
}
${MORE_FIELDS}
`
