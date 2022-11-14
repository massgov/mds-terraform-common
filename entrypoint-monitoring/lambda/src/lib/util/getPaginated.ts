import ScanLogger from "../ScanLogger";

let lastBatchId = 0

// @todo Replace all the `any` types with actual definition.
export default async function* getPaginated<
  Output,
  Item,
>(params: {
  input: any,
  client: any,
  CommandClass: any,
  maxRequests?: number,
  logger: ScanLogger,
  reader: (data: Output) => AsyncGenerator<Item>,
}): AsyncGenerator<Item> {
  const {
    maxRequests = 10,
    input,
    client,
    CommandClass,
    logger,
    reader
  } = params

  const batchId = lastBatchId++;

  for (let i = 0; i < maxRequests; i++) {
    logger.debug(`Batch #${batchId}: making request #${i+1} with input: ${JSON.stringify(input)}`)

    const command = new CommandClass(input)
    const data = await client.send(command)

    logger.debug(`Batch #${batchId}: got response from request #${i+1}`)

    // The callback returns true once it's done and there is no more data.
    const isComplete: boolean = yield* reader(data)
    if (isComplete) {
      logger.debug(`Batch #${batchId}: the job is done, leaving.`)
      return;
    }
  }

  // This point could only be reached in case there was not enough requests
  // to list all the data. We must error here.
  throw new Error('Too much data. Either there is an infinite loop or the limits must be increased.')
}