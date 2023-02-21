export const logLevels = ['debug', 'log', 'error'] as const;

export type LogLevel = typeof logLevels[number];
