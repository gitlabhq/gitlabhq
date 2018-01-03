export default (time = 0) => new Promise((resolve) => {
  setTimeout(resolve, time);
});
