defmodule NFTMediaHandler.R2.Uploader do
  @moduledoc """
  Uploads an image to R2
  """

  def upload_image(file_binary, file_name) do
    bucket_name = Application.get_env(:ex_aws, :bucket_name)

    with %ExAws.Operation.S3{} = request <- ExAws.S3.put_object(bucket_name, file_name, file_binary),
         {:ok, result} <- ExAws.request(request) do
      {:ok, result, "#{Application.get_env(:ex_aws, :s3)[:public_r2_url]}/#{file_name}"}
    end
  end
end
