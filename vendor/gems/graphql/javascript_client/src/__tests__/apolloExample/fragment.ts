import { gql } from '@apollo/client';

export const MORE_FIELDS = gql`
fragment MoreFields on Query { __typename }
`
