export function someFunction() {
  throw new Error('someFunction should not be called');
}

export function otherFunction() {
  someFunction();
}
