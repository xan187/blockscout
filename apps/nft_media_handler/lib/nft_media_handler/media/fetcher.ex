defmodule NFTMediaHandler.Media.Fetcher do
  @moduledoc """
    Module fetches media from various sources
  """

  def fetch_media(url) when is_binary(url) do
    with media_type when not is_nil(media_type) <- media_type(url),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, [], follow_redirect: true, max_body_length: 10_000_000) do
      {:ok, media_type, body}
    else
      nil ->
        {:error, :unsupported_media_type}

      {:ok, %HTTPoison.Response{status_code: status_code, body: _body}} ->
        {:error, status_code}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def media_type("data:image/" <> data) do
    [type, _] = String.split(data, ";", parts: 2)
    {"image", type}
  end

  def media_type("data:video/" <> data) do
    [type, _] = String.split(data, ";", parts: 2)
    {"video", type}
  end

  def media_type("data:" <> _data) do
    nil
  end

  def media_type(media_src) when not is_nil(media_src) do
    ext = media_src |> Path.extname() |> String.trim()

    mime_type =
      if ext == "" do
        process_missing_extension(media_src)
      else
        ext_with_dot =
          media_src
          |> Path.extname()

        "." <> ext = ext_with_dot

        ext
        |> MIME.type()
      end

    if mime_type do
      mime_type |> String.split("/") |> List.to_tuple()
    else
      nil
    end
  end

  def media_type(nil), do: nil

  def process_missing_extension(media_src) do
    case HTTPoison.head(media_src, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} ->
        headers_map = Map.new(headers, fn {key, value} -> {String.downcase(key), value} end)
        headers_map["content-type"]

      _ ->
        nil
    end
  end
end
