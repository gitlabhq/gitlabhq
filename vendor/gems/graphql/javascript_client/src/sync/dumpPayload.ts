import fs from 'fs';

interface DumpPayloadOptions {
  dumpPayload: string | true,
}

export default function dumpPayload(payload: Object, options: DumpPayloadOptions) {
  let payloadStr = JSON.stringify(payload, null, 2) + "\n"
  if (options.dumpPayload == true) {
    process.stdout.write(payloadStr)
  } else {
    fs.writeFileSync(options.dumpPayload, payloadStr, 'utf8')
  }
}
