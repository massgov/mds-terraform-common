import crypto from "crypto";

interface Args {
  key: string
  input: string
}

export default function({ key, input }: Args): boolean {
  const keyByteLength = Buffer.byteLength(key)

  // We intentionally allocate buffers of the same constant length. It's
  // required by the comparison function.
  const keyBuffer = Buffer.alloc(keyByteLength)
  const inputBuffer = Buffer.alloc(keyByteLength)

  keyBuffer.write(key)
  inputBuffer.write(input)

  const buffersEqual = crypto.timingSafeEqual(keyBuffer, inputBuffer)
  const sameLength = key.length === input.length

  return (buffersEqual && sameLength)
}
