// import gleam/dynamic.{type Dynamic}
// import gleam/list
// // Type definitions
// type Record {
//   Record(data: Dynamic, timestamp: Int)
// }

// type Session {
//   Session(id: String, records: List(Record), state: Dynamic)
// }

// // Individual record processor
// type RecordProcessor =
//   fn(Record, Dynamic) -> #(Record, Dynamic)

// // Session processor
// type SessionProcessor =
//   fn(Session) -> Session

// // Sessionization function
// type Sessionizer =
//   fn(Record, List(Session)) -> List(Session)

// // Pipeline configuration
// type PipelineConfig {
//   PipelineConfig(
//     record_processors: List(RecordProcessor),
//     sessionizer: Sessionizer,
//     session_processors: List(SessionProcessor),
//   )
// }

// // Main pipeline function
// pub fn process_record(record: Record, config: PipelineConfig, sessions: List(Session), state: Dynamic) {
//   let #(processed_record, new_state) = apply_record_processors(record, config.record_processors, state)
//   let updated_sessions = config.sessionizer(processed_record, sessions)

//   let final_sessions = case config.process_individual_first {
//     True -> apply_session_processors(updated_sessions, config.session_processors)
//     False -> {
//       let #(individually_processed_record, _) = apply_record_processors(record, config.record_processors, new_state)
//       apply_session_processors(updated_sessions, config.session_processors)
//         |> list.map(fn(session) {
//           Session(..session, records: [individually_processed_record, ..session.records])
//         })
//     }
//   }

//   #(final_sessions, new_state)
// }

// // Helper functions
// fn apply_record_processors(record, processors, state) {
//   // Apply each processor in sequence, threading through the state
//   list.fold(processors, #(record, state), fn(acc, processor) {
//     let #(r, s) = acc
//     processor(r, s)
//   })
// }

// fn apply_session_processors(sessions, processors) {
//   // Apply each processor to each session
//   list.map(sessions, fn(session) {
//     list.fold(processors, session, fn(s, processor) { processor(s) })
//   })
// }
