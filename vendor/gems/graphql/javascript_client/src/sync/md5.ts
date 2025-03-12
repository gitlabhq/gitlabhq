import crypto from 'crypto'

// Return the hex-encoded md5 hash of `inputString`
function md5(inputString: string): string {
  return crypto.createHash("md5")
    .update(inputString)
    .digest("hex")
}

export default md5
