import birl
import birl/duration
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string_builder
import record.{DInt, DString, DTime}
import string_utils

pub type HttpEvent {
  HttpEvent(
    client_ip: String,
    user_agent: String,
    timestamp: birl.Time,
    method: String,
    path: String,
    status: Int,
    content_length: Int,
  )
}

pub fn random_event() -> HttpEvent {
  let random_ip = {
    let a = int.random(255) |> int.to_string
    let b = int.random(255) |> int.to_string
    let c = int.random(255) |> int.to_string
    let d = int.random(255) |> int.to_string
    string_builder.from_string(a)
    |> string_builder.append(".")
    |> string_builder.append(b)
    |> string_builder.append(".")
    |> string_builder.append(c)
    |> string_builder.append(".")
    |> string_builder.append(d)
    |> string_builder.to_string()
  }
  let random_user_agent =
    ["Mozilla", "Chrome", "Safari", "Firefox", "Edge", "Opera"]
    |> iterator.from_list
    |> iterator.at(int.random(5))
    |> result.unwrap("Mozilla")
  let random_timestamp = {
    let random_offset = int.random(3600)
    birl.now() |> birl.add(duration.seconds(random_offset))
  }
  let random_method = case int.random(2) {
    0 -> "GET"
    _ -> "POST"
  }
  let random_path = "/" <> string_utils.get_random_string()
  let random_status = 200 + int.random(399)
  let random_content_length = int.random(1000)
  HttpEvent(
    random_ip,
    random_user_agent,
    random_timestamp,
    random_method,
    random_path,
    random_status,
    random_content_length,
  )
}

pub fn to_record(event: HttpEvent) -> record.Record {
  record.new()
  |> record.add_field("client_ip", DString(event.client_ip))
  |> record.add_field("user_agent", DString(event.user_agent))
  |> record.add_field("timestamp", DTime(event.timestamp))
  |> record.add_field("method", DString(event.method))
  |> record.add_field("path", DString(event.path))
  |> record.add_field("status", DInt(event.status))
  |> record.add_field("content_length", DInt(event.content_length))
}
