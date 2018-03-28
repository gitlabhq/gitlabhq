export default function removeBreakLine (data) {
  return data.replace(/\r?\n|\r/g, ' ');
}
