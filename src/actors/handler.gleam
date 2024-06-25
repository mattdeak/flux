import processors/processor
import record

pub type RecordHandler(state) =
  fn(record.Record, state) -> Result(record.Record, processor.ProcessorError)

pub fn from_processor(p: processor.Processor(state)) -> RecordHandler(state) {
  // Handle more as we add more
  case p {
    processor.RecordProcessor(func) -> func
    _ -> panic
  }
}
