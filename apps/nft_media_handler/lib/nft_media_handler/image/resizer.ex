defmodule NFTMediaHandler.Image.Resizer do
  @moduledoc """
  Resizes an image
  """

  @sizes [{20, "20x20"}, {30, "30x30"}, {190, "190x190"}, {300, "300x300"}]
  require Logger

  def resize(file_path, image, url, extension) do
    max_size = max(Image.width(image), Image.height(image))

    Enum.map(@sizes, fn {int_size, size} ->
      new_file_name = generate_file_name(url, extension, size)
      path = file_path <> new_file_name

      with {:size, true} <- {:size, max_size >= int_size},
           {:ok, resized_image} <- Image.thumbnail(image, size, []),
           {:ok, _result} <- Image.write(resized_image, path) |> dbg() do
        {size, File.read!(path), new_file_name}
      else
        error ->
          error_message =
            case error do
              {:size, _} -> "Skipped #{size} resizing due to small image size"
              error -> "Error while #{size} resizing: #{inspect(error)}"
            end

          Logger.warn(error_message)
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def sizes, do: @sizes

  def generate_file_name(url, extension, size) do
    "#{:sha |> :crypto.hash("#{url}_#{DateTime.to_unix(DateTime.utc_now())}") |> Base.encode16(case: :lower)}_#{size}#{extension}"
  end
end
