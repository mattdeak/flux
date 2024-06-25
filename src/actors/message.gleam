import processors/processor
import record

pub type Message =
  Result(record.Record, processor.ProcessorError)

pub fn from_error(error: processor.ProcessorError) -> Message {
  Error(error)
}

pub fn from_record(record: record.Record) -> Message {
  Ok(record)
}
