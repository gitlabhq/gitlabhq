import { RuleTester } from 'eslint';
import { afterAll, it, describe } from 'vitest';

RuleTester.afterAll = afterAll;
RuleTester.it = it;
RuleTester.itOnly = it.only;
RuleTester.describe = describe;
