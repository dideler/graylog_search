defmodule GraylogSearch do
  @moduledoc """
  GraylogSearch constructs search queries in a composable manner.

  It more or less follows [Graylog's search query language](http://docs.graylog.org/en/latest/pages/queries.html).

  ## Basic Usage

  All queries start with a base URL to the graylog instance.
  ```
  GraylogSearch.new("https://graylog.example.com")
  ```

  And end with requesting the constructed URL.
  ```
  GraylogSearch.url()
  ```

  In between the start and end, the query can be composed in various ways.
  ```
  GraylogSearch.new("https://graylog.example.com")
  |> GraylogSearch.for("message", "ssh login")
  |> GraylogSearch.and_for("hostname", "service*.example.com")
  |> GraylogSearch.minutes_ago(5)
  |> GraylogSearch.url()
  ```

  See the API docs below for other ways to construct a query.
  """

  @doc """
  Given a base URL to the Graylog instance (i.e. scheme and host name, no path or query string),
  returns a URI for GraylogSearch pipelines.
  """
  @doc group: :generic
  @spec new(String.t()) :: URI.t()
  def new(url) when is_binary(url) do
    uri = URI.parse(url)
    %URI{uri | path: "/search"}
  end

  @doc "Returns a URL to perform the search"
  @doc group: :generic
  @spec url(URI.t() | {:error, atom()}) :: String.t() | {:error, atom()}
  def url(%URI{} = uri), do: URI.to_string(uri)
  def url({:error, _reason} = err), do: err

  @doc """
  Search for a message by the given query term or phrase.
  This function can be chained to combine queries with AND.

  By default, all fields are included in the search
  when a field to search in is not specified.
  """
  @doc group: :operators
  @spec for(URI.t(), String.t()) :: URI.t()
  def for(%URI{} = uri, query) when is_binary(query) do
    sanitised_query = sanitise_input(query)
    and_query(uri, sanitised_query)
  end

  @doc """
  Searches for a term or phrase in a specific message field.

  Unlike `for/2` which searches all message fields.
  """
  @doc group: :operators
  @spec for(URI.t(), atom(), String.t()) :: URI.t()
  def for(%URI{} = uri, field, query) when is_atom(field) and is_binary(query) do
    sanitised_query = sanitise_input(query)
    and_field_query(uri, field, sanitised_query)
  end

  @doc "Aliases `for/2`"
  @doc group: :operators
  @spec and_for(URI.t(), String.t()) :: URI.t()
  def and_for(uri, query), do: __MODULE__.for(uri, query)

  @doc "Aliases `for/3`"
  @doc group: :operators
  @spec and_for(URI.t(), atom(), String.t()) :: URI.t()
  def and_for(uri, field, query), do: __MODULE__.for(uri, field, query)

  defp and_query(uri, nil), do: uri

  defp and_query(%URI{query: nil} = uri, query) do
    query_string = URI.encode_query(%{"q" => query})
    %URI{uri | query: query_string}
  end

  defp and_query(%URI{} = uri, query) do
    query_string =
      uri.query
      |> URI.decode_query()
      |> Map.get_and_update("q", &add_and_query(&1, query))
      |> (fn {_old_query, new_query} -> new_query end).()
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  defp and_field_query(uri, _field, nil), do: uri

  defp and_field_query(uri, field, query) do
    field_query = ~s(#{field}:"#{query}")
    and_query(uri, field_query)
  end

  @doc """
  Search messages by another term or phrase.

  Uses the OR operator to combine queries.
  """
  @doc group: :operators
  @spec or_for(URI.t(), String.t()) :: URI.t()
  def or_for(%URI{} = uri, query) when is_binary(query) do
    sanitised_query = sanitise_input(query)
    or_query(uri, sanitised_query)
  end

  @doc """
  Searches for another term or phrase in a specific message field.

  Unlike `or_for/2` which searches all message fields.
  """
  @doc group: :operators
  @spec or_for(URI.t(), atom(), String.t()) :: URI.t()
  def or_for(%URI{} = uri, field, query) when is_atom(field) and is_binary(query) do
    sanitised_query = sanitise_input(query)
    or_field_query(uri, field, sanitised_query)
  end

  defp or_query(uri, nil), do: uri

  defp or_query(%URI{query: nil} = uri, _query), do: uri

  defp or_query(%URI{} = uri, query) do
    query_string =
      uri.query
      |> URI.decode_query()
      |> Map.get_and_update("q", &add_or_query(&1, query))
      |> (fn {_old_query, new_query} -> new_query end).()
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  defp or_field_query(uri, _field, nil), do: uri

  defp or_field_query(uri, field, query) do
    field_query = ~s(#{field}:"#{query}")
    or_query(uri, field_query)
  end

  @doc """
  Search for messages that do not include a term or phrase.

  Uses the NOT operator. Can be chained to combine queries with AND NOT.
  """
  @doc group: :operators
  @spec not_for(URI.t(), String.t()) :: URI.t()
  def not_for(%URI{} = uri, query) when is_binary(query) do
    sanitised_query = sanitise_input(query)
    not_query(uri, sanitised_query)
  end

  @doc """
  Searches for messages that do not include a term or phrase in a specific field.

  Unlike `not_for/2` which searches all message fields.
  """
  @doc group: :operators
  @spec not_for(URI.t(), atom(), String.t()) :: URI.t()
  def not_for(%URI{} = uri, field, query) when is_atom(field) and is_binary(query) do
    sanitised_query = sanitise_input(query)
    not_field_query(uri, field, sanitised_query)
  end

  defp not_query(uri, nil), do: uri

  defp not_query(%URI{query: nil} = uri, query) do
    query_string = URI.encode_query(%{"q" => "NOT #{query}"})
    %URI{uri | query: query_string}
  end

  defp not_query(%URI{} = uri, query) do
    query_string =
      uri.query
      |> URI.decode_query()
      |> Map.get_and_update("q", &add_not_query(&1, query))
      |> (fn {_old_query, new_query} -> new_query end).()
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  defp not_field_query(uri, _field, nil), do: uri

  defp not_field_query(uri, field, query) do
    field_query = ~s(#{field}:"#{query}")
    not_query(uri, field_query)
  end

  @doc "Aliases `not_for/2`"
  @doc group: :operators
  def and_not(uri, query), do: not_for(uri, query)

  @doc "Aliases `not_for/3`"
  @doc group: :operators
  def and_not(uri, field, query), do: not_for(uri, field, query)

  defp add_and_query(existing_query, query_addition),
    do: add_to_query(existing_query, query_addition, " AND ")

  defp add_or_query(existing_query, query_addition),
    do: add_to_query(existing_query, query_addition, " OR ")

  defp add_not_query(existing_query, query_addition),
    do: add_to_query(existing_query, query_addition, " AND NOT ")

  defp add_to_query(existing_query, query_addition, delimiter) do
    new_query = existing_query <> delimiter <> query_addition
    {existing_query, new_query}
  end

  @doc """
  Search messages within an absolute time range.

  Datetimes expected to be UTC in ISO 8601 format.
  """
  @doc group: :time
  @spec between(URI.t(), String.t(), String.t()) :: URI.t() | {:error, atom()}
  def between(%URI{} = uri, from, to) when is_binary(from) and is_binary(to) do
    with {:ok, from_dt, _utc_offset} <- DateTime.from_iso8601(from),
         {:ok, to_dt, _utc_offset} = DateTime.from_iso8601(to) do
      between(uri, from_dt, to_dt)
    end
  end

  @spec between(URI.t(), DateTime.t(), DateTime.t()) :: URI.t()
  def between(%URI{} = uri, %DateTime{} = from, %DateTime{} = to) do
    utc_iso_ms = fn dt -> cast_millisecond(dt) |> DateTime.to_iso8601() end
    do_between(uri, utc_iso_ms.(from), utc_iso_ms.(to))
  end

  @spec between(URI.t(), NaiveDateTime.t(), NaiveDateTime.t()) :: URI.t()
  def between(%URI{} = uri, %NaiveDateTime{} = from, %NaiveDateTime{} = to) do
    utc_iso_ms = fn dt -> cast_millisecond(dt) |> NaiveDateTime.to_iso8601() |> Kernel.<>("Z") end
    do_between(uri, utc_iso_ms.(from), utc_iso_ms.(to))
  end

  defp do_between(uri, from, to) do
    query_string =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.delete("relative")
      |> Map.put("rangetype", "absolute")
      |> Map.put("from", from)
      |> Map.put("to", to)
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  defp cast_millisecond(%NaiveDateTime{microsecond: {0, n}} = dt) when n < 3 do
    %NaiveDateTime{dt | microsecond: {0, 3}}
  end

  defp cast_millisecond(%DateTime{microsecond: {0, n}} = dt) when n < 3 do
    %DateTime{dt | microsecond: {0, 3}}
  end

  defp cast_millisecond(%NaiveDateTime{} = dt) do
    NaiveDateTime.truncate(dt, :millisecond)
  end

  defp cast_millisecond(%DateTime{} = dt) do
    DateTime.truncate(dt, :millisecond)
  end

  @doc """
  Search messages with a relative time range in minutes.

  From the given amount of minutes ago to the time the search is performed.
  """
  @doc group: :time
  @spec minutes_ago(URI.t(), pos_integer) :: URI.t()
  def minutes_ago(%URI{} = uri, n) when is_integer(n) and n > 0 do
    relative_time_range(uri, 60 * n)
  end

  @doc """
  Search messages with a relative time range in hours.

  From the given amount of hours ago to the time the search is performed.
  """
  @doc group: :time
  @spec hours_ago(URI.t(), pos_integer) :: URI.t()
  def hours_ago(%URI{} = uri, n) when is_integer(n) and n > 0 do
    relative_time_range(uri, 60 * 60 * n)
  end

  @doc """
  Search messages with a relative time range in days.

  From the given amount of days ago to the time the search is performed.
  """
  @doc group: :time
  @spec days_ago(URI.t(), pos_integer) :: URI.t()
  def days_ago(%URI{} = uri, n) when is_integer(n) and n > 0 do
    relative_time_range(uri, 60 * 60 * 24 * n)
  end

  defp relative_time_range(uri, sec) do
    query_string =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.drop(["from", "to"])
      |> Map.put("rangetype", "relative")
      |> Map.put("relative", sec)
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  @doc """
  Search messages within a time range specified by natural language.

  Consult the [natty natural language parser](http://natty.joestelmach.com/doc.jsp#syntax_list)
  for details on supported date/time formats.
  """
  @doc group: :time
  @spec within(URI.t(), String.t()) :: URI.t()
  def within(%URI{} = uri, date_expression) when is_binary(date_expression) do
    sanitised_expression = sanitise_input(date_expression)
    do_within(uri, sanitised_expression)
  end

  defp do_within(uri, nil), do: uri

  defp do_within(uri, date_expression) do
    query_string =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.drop(["from", "to"])
      |> Map.put("rangetype", "keyword")
      |> Map.put("keyword", date_expression)
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  @doc """
  Includes the given fields in the message results.

  Requires extractors to exist for the fields being specified.
  """
  @doc group: :generic
  @spec show_fields(URI.t(), [atom()]) :: URI.t()
  def show_fields(%URI{} = uri, fields) when is_list(fields) do
    query_string =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.put("fields", Enum.join(fields, ","))
      |> URI.encode_query()

    %URI{uri | query: query_string}
  end

  defp sanitise_input(query) when is_binary(query) do
    case String.trim(query) do
      "" -> nil
      query -> query
    end
  end
end
