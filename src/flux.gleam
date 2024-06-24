import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import input
import record
import processor

pub fn main() {
  let assert Ok(recipient) = actor.start(Nil, handle_recipient)
  let assert Ok(_) =
    input.start_random_generator(input.Constant(1000), recipient)

  process.sleep_forever()
}

fn handle_recipient(
  msg: record.Record,
  state: Nil,
) -> actor.Next(record.Record, Nil) {
  let assert Ok(new_record) = msg |> processor.identity |> processor.count_num_a(_, "random_string","a_count")

  io.debug(new_record)
  actor.continue(state)
}
