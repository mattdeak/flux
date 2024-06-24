import actors/processor
import record

pub type RecordHandler(state) =
  fn(record.Record, state) -> Result(record.Record, processor.ProcessorError)

pub fn from_processor(p: processor.Processor) -> RecordHandler(Nil) {
  // Handle more as we add more
  case p {
    processor.RecordProcessor(func) -> fn(record, _) { func(record) }
  }
}
