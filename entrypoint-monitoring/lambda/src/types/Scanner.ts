import Interconnections from "../lib/Interconnections";

export default interface Scanner {
  scan(interconnections: Interconnections): Promise<void>
}
