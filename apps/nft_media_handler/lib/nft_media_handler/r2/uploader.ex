defmodule NFTMediaHandler.R2.Uploader do
  @moduledoc """
  Uploads an image to R2/S3
  """

  @spec upload_image(binary(), binary()) :: {:error, any()} | {:ok, any(), nonempty_binary()}
  def upload_image(file_binary, file_name) do
    r2_config = Application.get_env(:ex_aws, :s3)

    with %ExAws.Operation.S3{} = request <- ExAws.S3.put_object(r2_config[:bucket_name], file_name, file_binary),
         {:ok, result} <- ExAws.request(request) do
      {:ok, result, "#{r2_config[:public_r2_url]}/#{file_name}"}
    end
  end
end
